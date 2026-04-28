#!/usr/bin/env python3
"""글로서리 기반 컨텍스트 인식 후처리.

Google Translator로 1차 생성된 en/zh/ja 번역의 가장 흔한 결함은
'고유명사가 동음이의 일반명사로 번역된 것' 이다.

이 스크립트는 다음 원칙으로 정정한다:
  1. 각 문항의 ko 필드(question/choices/explanation)에서 글로서리 ko_form이 등장하는지 확인
  2. 등장하면 같은 문항의 en/zh/ja 필드에서 해당 글로서리의 bad_forms를 correct 로 치환
  3. ko에 ko_form 이 없으면 치환하지 않음 (오탐 방지)

이 방식은 LLM API 없이 결정적으로 적용 가능하고, 가장 심각한 인명·지명·계책명
오역을 한 번에 잡아낸다. 미세한 의미 오역(문장 흐름)은 별도의 LLM 재번역 단계에서
처리해야 한다.

사용법:
  python3 scripts/apply_glossary_postfix.py [--dry-run]
"""
from __future__ import annotations

import argparse
import json
import re
from pathlib import Path
from collections import Counter

ROOT = Path(__file__).resolve().parent.parent
GLOSSARY = ROOT / 'scripts' / 'translation_glossary.json'
QUESTIONS = ROOT / 'assets' / 'data' / 'questions.json'


def load_glossary() -> list[dict]:
    """카테고리별 글로서리를 평탄화하여 반환."""
    raw = json.loads(GLOSSARY.read_text(encoding='utf-8'))
    flat: list[dict] = []
    for cat, entries in raw.items():
        if cat.startswith('_'):
            continue
        for e in entries:
            flat.append(e)
    return flat


def ko_contains(text: str, ko_form: str) -> bool:
    """ko_form이 ko 텍스트에 포함되는지 검사. 한국어는 단어 경계가 모호하므로 단순 in 검사."""
    return ko_form in text


# 자연어 컨텍스트에서 광범위하게 등장해 false positive를 일으키는 단어들.
# 글로서리에 들어 있어도 이 목록의 bad_form은 적용을 건너뛴다.
EN_BLACKLIST = {
    'after', 'luck', 'positive', 'reason', 'mark', 'court', 'ball', 'company',
    'mistress', 'longevity', 'reservoir', 'uprising', 'locust', 'magnitude',
    'assumption', 'home', 'silk', 'sample', 'meridian', 'foreigner',
    'preface', 'standing', 'stand up',
}
CJK_BLACKLIST = {'后', '正', '胃', '運', '兄', '虫', '正史'}


def is_safe_bad_form(bad: str) -> bool:
    """광범위 false positive를 일으키는 bad_form은 적용 제외."""
    if not bad:
        return False
    # 단일 CJK 글자는 거의 모두 일반어 — 제외
    if len(bad) == 1 and re.match(r'[぀-ヿ一-鿿]', bad):
        return False
    if bad in CJK_BLACKLIST:
        return False
    if bad.lower() in EN_BLACKLIST:
        return False
    return True


def replace_in_text(text: str, bad: str, good: str) -> tuple[str, int]:
    """대소문자 무시 + 영문은 단어 경계 보존."""
    if not bad or bad == good or not is_safe_bad_form(bad):
        return text, 0
    # 영문(라틴 알파벳 포함)은 단어 경계 + 대소문자 무시
    if re.search(r'[A-Za-z]', bad):
        pattern = re.compile(r'(?<![A-Za-z])' + re.escape(bad) + r'(?![A-Za-z])',
                             re.IGNORECASE)
        new, n = pattern.subn(good, text)
        return new, n
    # CJK는 단순 치환
    if bad in text:
        count = text.count(bad)
        return text.replace(bad, good), count
    return text, 0


def process(dry_run: bool = False) -> tuple[dict, list]:
    glossary = load_glossary()
    data = json.loads(QUESTIONS.read_text(encoding='utf-8'))

    stats: Counter[str] = Counter()
    examples: list[str] = []
    sample_limit = 30

    for q in data:
        ko_blob = ' '.join([
            q['question']['ko'],
            ' '.join(q['choices']['ko']),
            q['explanation']['ko'],
        ])
        for entry in glossary:
            ko_form = entry['ko_form']
            if not ko_contains(ko_blob, ko_form):
                continue
            for lang in ('en', 'zh', 'ja'):
                good = entry['correct'].get(lang, '')
                if not good:
                    continue
                bads = entry['bad_forms'].get(lang, [])
                # 각 필드에 적용
                for field in ('question', 'explanation'):
                    original = q[field][lang]
                    new = original
                    for bad in bads:
                        new, n = replace_in_text(new, bad, good)
                        if n > 0:
                            stats[f'{lang}/{ko_form}/{bad}'] += n
                            if len(examples) < sample_limit:
                                examples.append(
                                    f"id={q['id']} {field}.{lang}: {bad!r} → {good!r}"
                                )
                    if new != original:
                        q[field][lang] = new
                # choices는 리스트
                for i, opt in enumerate(q['choices'][lang]):
                    new = opt
                    for bad in bads:
                        new, n = replace_in_text(new, bad, good)
                        if n > 0:
                            stats[f'{lang}/{ko_form}/{bad}'] += n
                            if len(examples) < sample_limit:
                                examples.append(
                                    f"id={q['id']} choices.{lang}[{i}]: {bad!r} → {good!r}"
                                )
                    if new != opt:
                        q['choices'][lang][i] = new

    if not dry_run:
        with QUESTIONS.open('w', encoding='utf-8') as f:
            json.dump(data, f, ensure_ascii=False, indent=2)
            f.write('\n')

    return stats, examples


def main() -> None:
    p = argparse.ArgumentParser()
    p.add_argument('--dry-run', action='store_true', help='파일 저장 없이 변경 통계만 출력')
    args = p.parse_args()

    stats, examples = process(dry_run=args.dry_run)
    total = sum(stats.values())
    print(f'총 치환 횟수: {total}')
    print(f'고유 글로서리 매칭: {len(stats)}')
    print(f'\n샘플 (최대 30개):')
    for ex in examples:
        print(f'  {ex}')

    # 가장 빈번한 치환 Top 15
    print(f'\n빈도 상위 15개:')
    for k, v in stats.most_common(15):
        print(f'  {v}회: {k}')


if __name__ == '__main__':
    main()
