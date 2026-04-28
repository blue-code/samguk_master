#!/usr/bin/env python3
"""ko를 원문으로 en/zh/ja를 일괄 재번역 (Anthropic API + 글로서리 강제).

apply_glossary_postfix.py 가 잡지 못하는 어색한 문장 흐름·문법 오류·고유명사
누락까지 한 번에 해결하기 위한 풀 재번역 단계.

전제 조건:
  pip install anthropic
  export ANTHROPIC_API_KEY=sk-ant-...

사용법:
  python3 scripts/retranslate_with_api.py                # 전체 재번역
  python3 scripts/retranslate_with_api.py --ids 1,2,3    # 특정 ID만
  python3 scripts/retranslate_with_api.py --start 100 --end 200
  python3 scripts/retranslate_with_api.py --dry-run      # API 호출 없이 프롬프트만 출력

비용·시간 고려:
  - 474 문항 × 입력 ~1.5K 토큰 + 출력 ~1K 토큰 ≈ 1.2M 토큰
  - claude-haiku-4-5 사용 시 약 $1~2 (캐시 사용 권장)
  - 글로서리는 system 프롬프트에 캐시되어 모든 요청에서 재사용
"""
from __future__ import annotations

import argparse
import json
import os
import sys
import time
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
GLOSSARY = ROOT / 'scripts' / 'translation_glossary.json'
QUESTIONS = ROOT / 'assets' / 'data' / 'questions.json'

MODEL = 'claude-haiku-4-5'

SYSTEM_TEMPLATE = """당신은 한국어 삼국지 퀴즈를 영어/중국어(간체)/일본어로 번역하는 번역가입니다.

## 절대 규칙
1. 한국어가 원문(source of truth). 의미를 정확히 보존합니다.
2. 인명·지명·계책명·사자성어는 반드시 아래 글로서리의 표기를 따릅니다.
3. 각 언어의 답안 보기 4개 순서는 한국어 보기 순서와 동일하게 유지합니다.
4. 의역하더라도 정답이 모호해지지 않게 하고, 보기 간 변별력을 유지합니다.
5. 일본어는 가타카나 한국어 음역을 쓰지 않고 표준 한자/일본어 독음을 사용합니다.
6. JSON 형식으로만 응답하고 추가 설명을 붙이지 않습니다.

## 글로서리 (한국어 → en / zh / ja)

{glossary_table}

## 출력 스키마
입력으로 받은 문항을 다음 JSON 형식으로 응답하세요:
{{
  "question": {{"en": "...", "zh": "...", "ja": "..."}},
  "choices": {{"en": ["...","...","...","..."], "zh": [...], "ja": [...]}},
  "explanation": {{"en": "...", "zh": "...", "ja": "..."}},
  "category": {{"en": "...", "zh": "...", "ja": "..."}}
}}
"""


def build_glossary_table(glossary_path: Path) -> str:
    raw = json.loads(glossary_path.read_text(encoding='utf-8'))
    rows: list[str] = []
    for cat, entries in raw.items():
        if cat.startswith('_'):
            continue
        rows.append(f'\n### {cat}')
        for e in entries:
            ko = e['ko_form']
            en = e['correct'].get('en', '-')
            zh = e['correct'].get('zh', '-')
            ja = e['correct'].get('ja', '-')
            rows.append(f'- {ko} → {en} / {zh} / {ja}')
    return '\n'.join(rows)


def build_user_prompt(q: dict) -> str:
    return json.dumps({
        'id': q['id'],
        'category_ko': q['category']['ko'],
        'difficulty': q['difficulty'],
        'question_ko': q['question']['ko'],
        'choices_ko': q['choices']['ko'],
        'answerIndex': q['answerIndex'],
        'explanation_ko': q['explanation']['ko'],
    }, ensure_ascii=False, indent=2)


def parse_args():
    p = argparse.ArgumentParser()
    p.add_argument('--ids', help='쉼표로 구분된 ID 목록')
    p.add_argument('--start', type=int, default=1)
    p.add_argument('--end', type=int, default=10**9)
    p.add_argument('--dry-run', action='store_true')
    p.add_argument('--out', default=str(QUESTIONS))
    return p.parse_args()


def main() -> int:
    args = parse_args()
    data = json.loads(QUESTIONS.read_text(encoding='utf-8'))
    glossary_table = build_glossary_table(GLOSSARY)
    system = SYSTEM_TEMPLATE.format(glossary_table=glossary_table)

    if args.ids:
        ids = {int(x) for x in args.ids.split(',')}
        targets = [q for q in data if q['id'] in ids]
    else:
        targets = [q for q in data if args.start <= q['id'] <= args.end]
    print(f'대상 문항: {len(targets)}개', file=sys.stderr)

    if args.dry_run:
        # 프롬프트 1건 미리보기
        if targets:
            print('--- system (앞 800자) ---')
            print(system[:800])
            print('...')
            print('\n--- user (첫 문항) ---')
            print(build_user_prompt(targets[0]))
        return 0

    try:
        from anthropic import Anthropic
    except ImportError:
        print('anthropic SDK 가 필요합니다: pip install anthropic', file=sys.stderr)
        return 1

    if not os.environ.get('ANTHROPIC_API_KEY'):
        print('ANTHROPIC_API_KEY 환경변수가 비어 있습니다.', file=sys.stderr)
        return 1

    client = Anthropic()
    by_id = {q['id']: q for q in data}
    successes = failures = 0

    for q in targets:
        try:
            resp = client.messages.create(
                model=MODEL,
                max_tokens=2048,
                system=[{
                    'type': 'text',
                    'text': system,
                    'cache_control': {'type': 'ephemeral'},
                }],
                messages=[{'role': 'user', 'content': build_user_prompt(q)}],
            )
            txt = resp.content[0].text.strip()
            # 모델이 ```json``` 펜스를 붙일 수 있어 제거
            if txt.startswith('```'):
                txt = txt.split('\n', 1)[1].rsplit('```', 1)[0].strip()
            translated = json.loads(txt)
            target = by_id[q['id']]
            for field in ('category', 'question', 'explanation'):
                for lang in ('en', 'zh', 'ja'):
                    if lang in translated.get(field, {}):
                        target[field][lang] = translated[field][lang]
            for lang in ('en', 'zh', 'ja'):
                if lang in translated.get('choices', {}):
                    opts = translated['choices'][lang]
                    if len(opts) == 4:
                        target['choices'][lang] = opts
            successes += 1
            print(f'  id={q["id"]} OK', file=sys.stderr)
        except Exception as e:  # noqa: BLE001
            failures += 1
            print(f'  id={q["id"]} FAIL: {e}', file=sys.stderr)
            time.sleep(2)

    Path(args.out).write_text(
        json.dumps(data, ensure_ascii=False, indent=2) + '\n',
        encoding='utf-8',
    )
    print(f'\n완료: 성공 {successes}, 실패 {failures}', file=sys.stderr)
    return 0


if __name__ == '__main__':
    raise SystemExit(main())
