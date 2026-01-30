# LULU App ver2 (MVP-F) - CLAUDE.md v5.0

> **"24명의 Elite Agent가 다태아+조산아 부모를 위한 최고의 앱을 만든다"**
>
> **Version**: 5.0 (UX UT 결과 + "둘 다" 제거 + Code Update 완료)
> **Last Updated**: 2026-01-30
> **Target Release**: 2026.02.17
> **Status**: Code Update 완료

---

## Quick Reference

```
┌─────────────────────────────────────────────────────────────────────────┐
│                         LULU 핵심 정보                                   │
├─────────────────────────────────────────────────────────────────────────┤
│                                                                         │
│  🎯 포지셔닝: "아기 울음을 AI가 통역해드려요. 쌍둥이도, 조산아도 완벽하게"│
│                                                                         │
│  💡 전략: 울음 분석으로 Hook → 조산아/다둥이 특화로 Lock                │
│                                                                         │
│  👥 에이전트: 24명 (경영4 + 제품4 + 개발6 + 의료4 + 마케팅2 + AI4)      │
│                                                                         │
│  🛠️ 기술: Flutter 3.0+ | Supabase | Provider | Midnight Blue 테마       │
│                                                                         │
│  📦 MVP-F: 5종 기록 (수유/수면/기저귀/놀이/건강)                        │
│                                                                         │
│  🎯 타겟: 다태아 조산아 부모 (연 9,500명, 전체 타겟 90%)                │
│                                                                         │
│  🚫 금지: 하드코딩 API키 | print문 | 빈 catch | "정상/비정상" 표현      │
│                                                                         │
│  ⚠️ v5.0 핵심: "둘 다" 버튼 완전 제거 + QuickRecordButton 적용 완료    │
│                                                                         │
└─────────────────────────────────────────────────────────────────────────┘
```

---

## v5.0 핵심 변경사항

### "둘 다" 버튼 완전 제거 (UX UT 결과)

```
┌─────────────────────────────────────────────────────────────────────────┐
│              ⚠️ 핵심 변경: "둘 다" 버튼 완전 제거 + 코드 적용 완료       │
├─────────────────────────────────────────────────────────────────────────┤
│                                                                         │
│  🚫 제거 완료                                                           │
│  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━  │
│  • BabyTabBar의 "둘 다" 옵션 → 제거됨                                  │
│  • BabySelector 컴포넌트 → 삭제됨 ✅                                    │
│  • 모든 기록 화면의 동시 기록 기능 → 제거됨                            │
│  • selectedBabyId = null ("둘 다" 의미) 로직 → 제거됨                  │
│                                                                         │
│  ✅ 적용된 대안                                                         │
│  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━  │
│  • 빠른 탭 전환 (원탭 < 1초)                                           │
│  • QuickRecordButton ("이전과 같이" 원탭 저장) ✅                       │
│  • 개별 기록 후 탭 전환하여 순차 기록                                  │
│                                                                         │
│  📊 변경 이유 (UX UT 결과)                                              │
│  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━  │
│  1. 혼란: "둘 다"가 정확히 무엇을 의미하는지 불명확                    │
│  2. 데이터 정확성: 동시 기록 시 각 아기별 미세한 차이 반영 불가        │
│  3. 3초 Rule: 탭 전환이 더 빠름                                        │
│                                                                         │
└─────────────────────────────────────────────────────────────────────────┘
```

### v5.0 Code Update 완료 상태

| 작업 | 파일 | 상태 |
|------|------|------|
| QuickRecordButton 생성 | `lib/shared/widgets/quick_record_button.dart` | ✅ |
| FeedingRecordScreen 수정 | BabySelector → BabyTabBar + QuickRecordButton | ✅ |
| SleepRecordScreen 수정 | 동일 | ✅ |
| DiaperRecordScreen 수정 | 동일 | ✅ |
| PlayRecordScreen 수정 | 동일 | ✅ |
| HealthRecordScreen 수정 | 동일 | ✅ |
| BabySelector 삭제 | `lib/shared/widgets/baby_selector.dart` | ✅ |
| GrowthInputScreen 수정 | BabySelector → BabyTabBar | ✅ |
| 빌드 검증 | `flutter analyze` 에러 0개 | ✅ |

---

## 프로젝트 개요

### 미션
```
"전 세계 모든 부모가 새벽 3시에도 한 손으로, 5초 안에,
아기의 다음 행동을 예측하고 안심할 수 있는 앱"
```

### MVP-F 컨셉: 균형 하이브리드
```
┌─────────────────────────────────────────────────────────────┐
│                                                             │
│   MVP-F = 조산아 기능 + 다태아 기능 균형                    │
│                                                             │
│   타겟: 다태아 조산아 부모 (9,500명/년) = 핵심 타겟         │
│         + 조산아 단태아 (7,500명)                           │
│         + 다태아 만삭 (4,000명)                             │
│         = 총 21,000명/년 (90% 커버)                         │
│                                                             │
│   핵심 차별화:                                              │
│   1. 빠른 탭 전환 + QuickRecordButton (v5.0)               │
│   2. 개별 교정연령 (아기별)                                 │
│   3. Fenton + WHO 차트 자동 전환                            │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

### 핵심 수치
| 지표 | 값 |
|------|-----|
| 한국 다태아/년 | 13,500 (5.7%) |
| 다태아 중 조산율 | 70.8% |
| 조산아+다태아 전용 앱 | 0개 (100% Gap) |
| 목표 NPS | +66.7 |
| 목표 TSR | 92.5% |

---

## 24 Elite Agents

```
┌─────────────────────────────────────────────────────────────────────────┐
│                    LULU Elite Agent Team (24 Agents)                    │
├─────────────────────────────────────────────────────────────────────────┤
│                                                                         │
│                           🎯 Product Owner                              │
│                                  │                                      │
│     ┌────────────┬───────────────┼───────────────┬────────────┐        │
│     │            │               │               │            │        │
│  ┌──▼──┐     ┌──▼──┐        ┌──▼──┐        ┌──▼──┐     ┌──▼──┐      │
│  │경영  │     │제품  │        │개발  │        │의료  │     │AI    │      │
│  │전략  │     │디자인│        │      │        │전문  │     │Audio │      │
│  │ 4명  │     │ 4명  │        │ 6명  │        │ 4명  │     │ 4명  │      │
│  └─────┘     └─────┘        └─────┘        └─────┘     └─────┘      │
│                                  │                                      │
│                           ┌──────▼──────┐                              │
│                           │ 마케팅/그로스 │                              │
│                           │     2명      │                              │
│                           └─────────────┘                              │
│                                                                         │
└─────────────────────────────────────────────────────────────────────────┘
```

### 경영/전략 (4명)

| # | 에이전트 | 역할 | 핵심 책임 |
|---|---------|------|----------|
| 1 | Product Strategist | 제품 전략 | 로드맵, MoSCoW 우선순위, 비전 |
| 2 | Market Analyst | 시장 분석 | TAM/SAM/SOM, 경쟁사 벤치마킹 |
| 3 | Business Modeler | 수익 모델 | Freemium 설계, Unit Economics |
| 4 | Project Manager | 스프린트 관리 | 일정, 리소스, 리스크 관리 |

### 제품/디자인 (4명)

| # | 에이전트 | 역할 | 핵심 책임 |
|---|---------|------|----------|
| 5 | UX Designer | 사용성 | 3초 Rule, 플로우, 와이어프레임 |
| 6 | UI Designer | 비주얼 | Midnight Blue 테마, 컴포넌트 |
| 7 | Multiple Births Specialist | 다태아 UX | 탭 전환, 비교 금지, "둘 다" 검증 |
| 8 | Mobile UX Expert | 모바일 | 한 손 조작, 야간 사용성, 피로 대응 |

### 개발 (6명)

| # | 에이전트 | 역할 | 핵심 책임 |
|---|---------|------|----------|
| 9 | Flutter Architect | 아키텍처 | Provider 패턴, 코드 구조 |
| 10 | Flutter Developer | 기능 개발 | 화면 구현, 위젯 개발 |
| 11 | Backend Developer | Supabase | Auth, DB, Storage, RLS |
| 12 | QA Engineer | 품질 | 테스트 케이스, 버그 추적 |
| 13 | Security Engineer | 보안 | 암호화, GDPR, 데이터 보호 |
| 14 | DevOps Engineer | CI/CD | 배포, 모니터링, 자동화 |

### 의료/전문 (4명)

| # | 에이전트 | 역할 | 핵심 책임 |
|---|---------|------|----------|
| 15 | Neonatology Specialist | 조산아 전문 | 교정연령, Fenton 차트, NICU |
| 16 | Pediatric Nurse | 신생아 케어 | 수유/수면 가이드, 실무 지식 |
| 17 | Clinical Data Analyst | 의료 데이터 | WHO 차트, 의료 통계 검증 |
| 18 | Medical Compliance | 의료 규제 | 면책 조항, COPPA, 의료기기 규정 |

### 마케팅/그로스 (2명)

| # | 에이전트 | 역할 | 핵심 책임 |
|---|---------|------|----------|
| 19 | Growth Marketer | 사용자 획득 | ASO, 바이럴, NICU 파트너십 |
| 20 | Content Creator | 콘텐츠 | SNS, 앱스토어 설명, PR |

### AI/Audio (4명) - Phase 2 전담

| # | 에이전트 | 역할 | 핵심 책임 | 검증 기준 |
|---|---------|------|----------|----------|
| 21 | Audio ML Engineer | 울음 ML 모델 | CNN 설계, 학습, 최적화 | 정확도 75%+, <10MB |
| 22 | On-Device ML Specialist | 모바일 ML | Core ML/TF Lite 변환 | 추론 <500ms, 배터리 <5%/hr |
| 23 | Infant Cry Researcher | 울음 연구 | Dunstan 검증, 조산아 울음 | 5가지 분류 과학적 근거 |
| 24 | Audio Privacy Specialist | 오디오 프라이버시 | 마이크 권한 UX, 정책 | 100% On-Device, 저장 X |

---

## MVP-F 5종 기록

### 기록 유형

```
┌─────────────────────────────────────────────────────────────────────────┐
│                         MVP-F 5종 기록                                   │
├─────────────────────────────────────────────────────────────────────────┤
│                                                                         │
│  ┌────────┬────────┬────────┬────────┬────────┐                        │
│  │  🍼    │  😴    │  👶    │  🎮    │  🏥    │                        │
│  │  수유   │  수면   │ 기저귀 │  놀이   │  건강   │                        │
│  │   ✅   │   ✅   │   ✅   │   ✅   │   ✅   │                        │
│  └────────┴────────┴────────┴────────┴────────┘                        │
│                                                                         │
│  공통 기능:                                                             │
│  • 3초 Rule 준수                                                       │
│  • 개별 기록 (탭 전환)                                                 │
│  • QuickRecordButton ("이전과 같이")                                   │
│  • BabyTabBar (교정연령 통합)                                          │
│                                                                         │
└─────────────────────────────────────────────────────────────────────────┘
```

### 기록별 상세

| 기록 | 아이콘 | 핵심 기능 | 조산아 고려 | UX 시안 |
|------|--------|----------|------------|---------|
| **수유** | 🍼 | 모유(좌/우/양쪽), 분유, 혼합, ml 자유입력 | - | RE 하이브리드 |
| **수면** | 😴 | 낮잠/밤잠 자동 제안 (시간 기반) | - | SE 하이브리드 |
| **기저귀** | 👶 | 소변/대변, 색상 선택(선택적), 경고문 | 대변 색상 중요 | 최종 |
| **놀이** | 🎮 | 터미타임/목욕/외출/놀이/독서/기타 | 터미타임 권장시간 | Sprint 6 UT |
| **건강** | 🏥 | 체온/증상/투약/병원방문, 면책 문구 | 조산아 체온 범위 | Sprint 6 UT |

### 건강 기록 체온 상태 표시

| 체온 | 상태 | 색상 | 메시지 |
|------|------|------|--------|
| <36.0°C | 저체온 | 파랑 | "체온이 낮아요. 보온에 신경써주세요." |
| 36.0-37.5°C | 정상 | 초록 | "정상 체온이에요." |
| 37.5-38.0°C | 미열 | 노랑 | "미열이 있어요. 지켜봐주세요." |
| >38.0°C | 발열 | 빨강 | "열이 있어요. 병원 방문을 권장해요." |

의료 면책: "이 정보는 참고용이며 의료 조언이 아닙니다."

---

## Tech Stack

```yaml
Framework: Flutter 3.0+
Language: Dart (SDK >=3.0.0 <4.0.0)
Platforms: iOS (MVP), Android (Phase 2)

State Management: Provider ^6.1.1
Backend: Supabase (Auth, DB, Storage)
AI: OpenAI GPT-4 (Phase 2)

Design:
  Theme: Midnight Blue (Dark Mode First)
  System: Glassmorphism
  Grid: 4px spacing
  Quick Action: 64x64dp
```

---

## UX 확정 시안 (v5.0)

### 화면별 SUS/TTC

| 화면 | 시안 | SUS | TTC | 핵심 특징 |
|------|------|-----|-----|----------|
| **메인** | F-3 컴팩트 | 87.4 | 2.18s | 탭+교정연령, 스크롤X, 울음 예약 |
| **수유** | RE 하이브리드 | 84.6 | 2.54s | 빠른기록+상세, 울음 연결 |
| **수면** | SE 하이브리드 | 87.0 | 2.0s | 원탭+자동제안, 행동기반 분류 |
| **기저귀** | 최종 | 85.4 | 1.74s | 색상선택(선택적), 경고문 |
| **놀이** | Sprint 6 UT | 80+ | <3s | 활동 유형 선택 |
| **건강** | Sprint 6 UT | 80+ | <3s | 체온/증상/투약 |

**목표**: SUS 80+, TTC < 3초

### 메인 화면 구조

```
┌─────────────────────────────────────────┐
│ [하늘이 교정42일] [바다 교정38일]       │ ← BabyTabBar (교정연령 통합)
├─────────────────────────────────────────┤
│ 오늘: 🍼5 😴13h 👶7 🎮2 🏥36.5°        │ ← TodaySummaryCard (5종)
├─────────────────────────────────────────┤
│ [Phase 2: 울음 분석 영역 예약]          │ ← CryAnalysisPlaceholder
├─────────────────────────────────────────┤
│ ╔══════╗ ╔══════╗ ╔══════╗ ╔══════╗   │
│ ║  🍼  ║ ║  😴  ║ ║  👶  ║ ║ 더보기║   │ ← QuickActionGrid (5종)
│ ╚══════╝ ╚══════╝ ╚══════╝ ╚══════╝   │   64x64dp
├─────────────────────────────────────────┤
│ 최근: 10:30 🍼 | 09:00 😴 | ...        │ ← MiniTimeline
└─────────────────────────────────────────┘
```

### 기록 화면 공통 구조 (v5.0)

```
┌─────────────────────────────────────────┐
│ ← [수유 기록]                           │ ← AppBar
├─────────────────────────────────────────┤
│ [하늘이] [바다]                         │ ← BabyTabBar (AppBar 아래 고정)
├─────────────────────────────────────────┤
│ ┌─────────────────────────────────────┐ │
│ │ 🍼 이전과 같이: 분유 120ml          │ │ ← QuickRecordButton
│ └─────────────────────────────────────┘ │
├─────────────────────────────────────────┤
│                                         │
│ [상세 입력 폼]                          │ ← 기록별 상세 입력
│                                         │
├─────────────────────────────────────────┤
│ [저장]                                  │
└─────────────────────────────────────────┘
```

---

## 다태아 UX 원칙 (v5.0)

### 필수 vs 금지

| ✅ 필수 | ❌ 금지 |
|---------|---------|
| 개별 기록 (탭 전환) | "둘 다" 버튼 |
| 비교 금지 UX | 동시 기록 UI |
| 교정연령 개별 계산 | 쌍둥이 비교 표현 |
| 빠른 탭 전환 (< 1초) | BabySelector 사용 |
| QuickRecordButton | selectedBabyId = null |
| 탭에 교정연령 통합 | "A가 B보다 많이" 표현 |

### 다태아 핵심 원칙

```
┌─────────────────────────────────────────────────────────────────────────┐
│                       다태아 UX 5대 원칙                                 │
├─────────────────────────────────────────────────────────────────────────┤
│                                                                         │
│  1️⃣ 개별 기록                                                          │
│     각 아기별로 따로 기록, 데이터 정확성 보장                           │
│                                                                         │
│  2️⃣ 빠른 탭 전환                                                        │
│     원탭으로 아기 전환 (< 1초), 3초 Rule 준수                           │
│                                                                         │
│  3️⃣ 교정연령 개별 계산                                                  │
│     각 아기별 독립적인 교정연령 계산 및 표시                            │
│                                                                         │
│  4️⃣ 비교 금지 UX                                                        │
│     쌍둥이 "우열" 표현 절대 금지, 차트 비교 X                           │
│                                                                         │
│  5️⃣ "이전과 같이" 버튼                                                  │
│     빠른 순차 기록 지원, 탭 전환 후 원탭 저장                           │
│                                                                         │
└─────────────────────────────────────────────────────────────────────────┘
```

---

## 데이터 모델

### 핵심 모델

```dart
/// 가족 모델 - 최상위 컨테이너
class FamilyModel {
  final String id;
  final String name;
  final List<BabyModel> babies;  // 1-4명
  final DateTime createdAt;

  BabyModel? get activeBaby;     // 현재 선택된 아기
  bool get isMultiple => babies.length > 1;
}

/// 아기 모델 - 다태아 고려 설계
class BabyModel {
  final String id;
  final String name;
  final DateTime birthDate;
  final int? gestationalWeeks;   // null = 만삭 (40주)
  final int? birthWeightGrams;
  final BabyType type;           // singleton, twin, triplet+
  final int? birthOrder;         // 다태아: 1, 2, 3...

  // 교정연령 (개별 계산)
  int? get correctedAgeInWeeks {
    if (gestationalWeeks == null || gestationalWeeks! >= 37) return null;
    final actualDays = DateTime.now().difference(birthDate).inDays;
    final correctionDays = (40 - gestationalWeeks!) * 7;
    return ((actualDays - correctionDays) / 7).floor();
  }

  bool get isPreterm => gestationalWeeks != null && gestationalWeeks! < 37;
}

enum BabyType { singleton, twin, triplet, quadruplet }
enum ActivityType { sleep, feeding, diaper, play, health }
```

### 활동 기록 모델 (v5.0 - 개별 기록만)

```dart
/// 활동 기록 - 개별 아기 기록 (v5.0)
class ActivityModel {
  final String id;
  final String babyId;           // v5.0: 단일 아기 ID만
  final ActivityType type;
  final DateTime startTime;
  final DateTime? endTime;
  final Map<String, dynamic>? data;  // 타입별 상세 데이터
}
```

---

## 프로젝트 구조

```
lib/
├── core/
│   ├── design_system/
│   │   ├── lulu_colors.dart           ← Midnight Blue 테마
│   │   └── lulu_typography.dart       ← 타이포그래피
│   └── utils/
│       ├── corrected_age_calculator.dart
│       └── sleep_type_suggester.dart  ← 수면 자동 제안
├── features/
│   ├── auth/
│   ├── onboarding/
│   ├── home/
│   │   ├── screens/
│   │   │   └── home_screen.dart       ← 메인 화면
│   │   └── widgets/
│   │       ├── today_summary_card.dart
│   │       ├── sweet_spot_hero_card.dart
│   │       └── cry_analysis_placeholder.dart ← Phase 2 예약
│   ├── record/
│   │   └── screens/
│   │       ├── feeding_record_screen.dart   ← v5.0 업데이트
│   │       ├── sleep_record_screen.dart     ← v5.0 업데이트
│   │       ├── diaper_record_screen.dart    ← v5.0 업데이트
│   │       ├── play_record_screen.dart      ← v5.0 업데이트
│   │       └── health_record_screen.dart    ← v5.0 업데이트
│   └── growth/
├── models/
│   ├── family_model.dart
│   ├── baby_model.dart
│   └── activity_model.dart
├── providers/
│   ├── family_provider.dart
│   ├── selected_baby_provider.dart
│   └── record_provider.dart
└── shared/
    └── widgets/
        ├── baby_tab_bar.dart           ← "둘 다" 제거됨
        ├── quick_action_grid.dart      ← 5종 버튼
        ├── quick_record_button.dart    ← v5.0 신규
        └── mini_timeline.dart
```

---

## 금지 사항 (Forbidden)

### 코드
```
- 하드코딩된 API 키
- print문 (debugPrint 사용)
- 빈 catch 블록
- TODO 없이 임시 코드
- 강제 언래핑 (!!)
- BabySelector 사용 (삭제됨)
```

### UX
```
- "둘 다" 버튼 (v5.0 제거)
- 쌍둥이 "우열" 비교 표현
- "정상/비정상" 판단 표현
- 의료 진단/치료 표현
- 3초 이상 걸리는 핵심 동작
```

### 의료
```
- "진단합니다", "치료합니다"
- 의료기기 암시 표현
- 출처 없는 의학 수치
```

---

## Phase/Sprint 체계

### Phase (제품 로드맵)

| Phase | 시기 | 목표 | 핵심 기능 |
|-------|------|------|----------|
| **Phase 1** | Q1 2026 | MVP-F | 5종 기록 + 다태아 + 조산아 |
| **Phase 2** | Q2 2026 | AI 울음 | 울음 분석 + 패턴 학습 |
| **Phase 3** | Q3 2026 | 워치 | Apple Watch 연동 |
| **Phase 4** | Q4 2026 | AI 통합 | 예측 + 코칭 |

### Sprint 현황

| Sprint | 기간 | 목표 | 상태 |
|--------|------|------|------|
| Sprint 0 | 0.5일 | 프로젝트 설정 | ✅ 완료 |
| Sprint 1 | 2일 | 모델 구현 | ✅ 완료 |
| Sprint 2 | 2일 | 온보딩 플로우 | ✅ 완료 |
| Sprint 3 | 3일 | 다태아 UI | ✅ 완료 |
| Sprint 4 | 2일 | 조산아 기능 | ✅ 완료 |
| Sprint 5 | 2일 | UX 리디자인 | ✅ 완료 |
| **Sprint 6** | **10일** | **새 UX 구현** | 🔄 진행 중 |
| Sprint 7 | 1주 | QA + 출시 | 예정 |

---

## 체크리스트

### 코드 리뷰 체크리스트

```
□ flutter analyze 오류 0개
□ 하드코딩 API 키 없음
□ print문 없음 (debugPrint 사용)
□ 빈 catch 블록 없음
□ 미사용 import 없음
□ 3초 Rule 준수
□ BabySelector 사용 안 함 (삭제됨)
□ "둘 다" 관련 로직 없음
```

### 다태아 UX 체크리스트

```
□ BabyTabBar 사용 (BabySelector X)
□ "둘 다" 버튼 없음
□ 교정연령 탭에 통합 표시
□ QuickRecordButton 포함
□ 비교 표현 없음
□ 개별 기록만 지원
```

### 의료 콘텐츠 체크리스트

```
□ 출처 명시됨
□ "진단/치료" 표현 없음
□ "정상/비정상" 표현 없음
□ 면책조항 포함
□ 쉬운 언어 사용
```

---

## 커밋 규칙

```yaml
Format: <type>(<scope>): <description>

Types:
  feat: 새 기능
  fix: 버그 수정
  refactor: 리팩토링
  style: 포맷팅
  docs: 문서
  test: 테스트

Scopes:
  onboarding, multiple, preterm, record, dashboard, widget, chart
```

---

## 문서 체계

```
┌─────────────────────────────────────────────────────────────────────────┐
│                         문서 역할 분리                                   │
├─────────────────────────────────────────────────────────────────────────┤
│                                                                         │
│  📘 CLAUDE.md = 고정 정보 (변경 적음)                                   │
│     • 기술 스택, 코딩 컨벤션, 에이전트 스펙                             │
│     • UX 원칙, 금지 사항, Phase/Sprint 체계                            │
│     • "둘 다" 버튼 제거 확정                                           │
│                                                                         │
│  📋 handoff.md = 동적 정보 (매 세션 변경)                               │
│     • 현재 버전, 현재 상태, 최근 작업                                  │
│     • TODO (여기에만!), 알려진 이슈                                    │
│                                                                         │
│  📜 CHANGELOG.md = 히스토리 (누적)                                      │
│     • 버전별 변경사항, 날짜별 기록                                     │
│                                                                         │
└─────────────────────────────────────────────────────────────────────────┘
```

---

**Last Updated**: 2026-01-30
**Version**: 5.0 (UX UT 결과 + "둘 다" 제거 + Code Update 완료)
**Agents**: 24명 (경영4 + 제품4 + 개발6 + 의료4 + 마케팅2 + AI4)

---

> *"3초 Rule, 원탭 전환, 개별 기록 - 피로한 부모를 위한 UX"*
> *"둘 다 버튼 대신, 빠른 탭 전환 + 이전과 같이 버튼"*
> *"다태아 + 조산아 = LULU 블루오션"*
