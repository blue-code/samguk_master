---
프로젝트명: samguk_master
작업일시: 2026-04-21 14:40
작성자: Kent
세션목적: 삼국지 덕력고사 기획 및 게임 로직 MVP 완료 문서 정리
---

# 🐉 삼국지 덕력고사 (Samguk Master)

[![Flutter](https://img.shields.io/badge/Flutter-3.x-blue.svg?logo=flutter)](https://flutter.dev) 
[![Dart](https://img.shields.io/badge/Dart-3.x-blue.svg?logo=dart)](https://dart.dev)
[![Platform](https://img.shields.io/badge/Platforms-iOS%20|%20Android%20|%20Windows-lightgrey.svg)]()

> "천하 삼분지계를 여는 치열한 지식의 전장!"
> **서버리스 기반의 고퀄리티 모바일 아케이드 삼국지 퀴즈 앱**

<br>

## 📌 프로젝트 소개
단순한 텍스트 퀴즈를 넘어, **진짜 모바일 게임을 하는 듯한 타격감과 몰입감**을 제공하는 삼국지 퀴즈 애플리케이션입니다.
백엔드 서버 없이 동작할 수 있도록 설계되어 네트워크 환경 제약 없이 언제든 플레이가 가능하며, 애플 Game Center 및 구글 Play Games와 연동되어 글로벌 랭킹 경쟁이 가능합니다.

<br>

## ✨ 핵심 기능 및 기획 스펙

### 1. ⚔️ **아케이드 서바이벌 시스템**
* **하트(목숨) 시스템**: 기본 3개의 생명(❤️)이 주어지며, 오답 시 하락합니다. 하트가 0이 되면 즉시 게임 오버 처리되어 긴장감을 극대화합니다.
* **콤보 보너스 시스템**: 연속해서 정답을 맞출 경우 콤보 배수 증폭기(Multiplier)가 적용되어, 연승할수록 기하급수적으로 점수가 오릅니다.
* **타임어택**: 문제당 주어지는 제한 시간(15초) 내에 빠르게 맞출수록 추가 점수를 얻습니다.

### 2. 🎨 **다이나믹 시각 연출 및 타격감**
* **역동적 배경 전환**: 문제 카테고리(전투/인물/일화 등)에 따라 뒷배경(다크 앰비언트 삼국지풍 일러스트)이 매 문제마다 실시간으로 바뀝니다.
* **애니메이션 피드백**: 정답 시 황금 인장(ZoomIn), 오답 시 부러진 검(Shake) 애니메이션이 자극적으로 팝업됩니다.

### 3. 🎧 **사운드 이펙트 & BGM**
* 앱 구동 및 퀴즈 진입 시 긴장감 있는 어두운 톤의 전장 **루핑 BGM**이 깔립니다.
* 통과(레벨업 화음) 효과음과 오답(하락음) 효과음이 믹스되어 눈과 귀를 동시에 자극합니다.
* 유저 편의를 위해 **Mute(음소거) 토글** 기능을 제공하며 기기 로컬에 영구 저장됩니다.

### 4. 🥇 **글로벌 랭킹 & 데이터 보존**
* `shared_preferences`를 사용해 오프라인 기기 내 **최고 점수(베스트 스코어)**를 영구 보존합니다.
* 기록 갱신 시 `games_services`를 통해 **Apple Game Center / Google Play Leaderboard**에 패킷을 전송하여 글로벌 랭킹 보드에 이름을 올립니다.

### 5. 📝 **오답 노트 기반의 교육 효과**
* 결과 창에서 게임 오버 전까지 유저가 "어떤 문제를 틀렸는지" 리스트업하여 제공합니다.
* 아코디언 형태의 전개 창을 통해 **정답과 자세한 역사적 해설**을 제공하여 게임 리텐션과 지식 습득의 재미를 높입니다.

<br>

## 🛠 기술 스택
* **Framework**: Flutter (상태 관리: `Provider` / MVVM 아키텍처)
* **Storage**: `shared_preferences` (로컬 데이터 캐싱)
* **Multimedia**: `audioplayers` (BGM / SFX 재생)
* **Animation**: `animate_do`
* **Integrations**: `games_services`, `flutter_launcher_icons`

<br>

## 🚀 로컬 구동 가이드 (개발자 환경)

```bash
# 1. 패키지 의존성 설치
flutter pub get

# (선택) 앱 런처 아이콘 동기화 업데이트가 필요한 경우
flutter pub run flutter_launcher_icons

# 2. Windows 데스크탑 앱 모드로 바로 실행
flutter run -d windows
```

<br>

---
*기획 및 구현: AI Assistant 'Kent' & Developer*
*최종 업데이트: 2026-04-21*
