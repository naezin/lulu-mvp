# LULU App - CLAUDE.md v7.4

> **Version**: 7.4 (v7.3 + Confidence Score + Scope Declaration + Learned Corrections)
> **Updated**: 2026-02-10
> **App**: v2.4.1+31 | **Commit**: Sprint 22 Badge-0 진행 중
> **Branch**: `sprint-22` (작업) → `main` (보호)
> **Sprint**: 22 Badge System
> **Target Release**: 2026.02 베타 → 2026.03 정식
> **Bundle ID**: com.lululabs.lulu

---

## v7.4 변경 사항

### v7.3 대비 추가

| 항목 | 설명 | 목적 |
|------|------|------|
| **Confidence Score** | 보고 시 확신도 8/10 형식 명시 | "추론 vs 확인" 구분 |
| **Scope Declaration** | 수정 / 제외 / 나중에 | Sprint 18 사고 재발 방지 |
| **Learned Corrections** | LC-1~5 교훈 구조화 | 반복 실수 방지 |

### Sprint 19.5 코드 위생 완료 (8 Phase)
- 하드코딩 한글 1,017건 → 0건 (100% i18n)
- Icons. 직접 사용 403건 → 0건 (100% LuluIcons)
- withOpacity 40건 → 0건 (솔리드 컬러)
- LuluRadius 99%, LuluShadows 100% 채택
- Pre-commit hook 6/6 게이트
- Supabase UI층 직접 호출 0건 (Repository 격리)
- 800줄+ 대형 파일 5개 분할
- ARB ko-en 키 차이 0건

### Sprint 20 Hotfix 완료
- 그룹 A~E 완료, TestFlight v2.4.1+31 배포 완료

### 디자인 시스템
- 아이콘 스타일 168개 전체 `_rounded` 통일 (outlined 혼재 제거)
- 대변 아이콘 교체 예정: `sanitizer_rounded` → 커스텀 SVG

### UX 결정사항
- 수면 중복: 같은 아기 새 수면 시 확인 다이얼로그 (자동 종료 아님)
- 저장 후 토스트: "저장됨  기록 보기 >" (2초, SnackBarAction)
- 스와이프 힌트: 3회만 표시 + Edit/Delete 아이콘만 (텍스트 제거)

---

## 프로젝트 상수 (컨텍스트 유실 방지)

> **사유**: 세션 전환 시 반복 참조 값을 매번 찾느라 시간 낭비 + 잘못된 값 사용 사고 발생.
> 이 테이블의 값은 **복사-붙여넣기로 사용**. 절대 기억에 의존하지 말 것.

| 항목 | 값 | 비고 |
|------|-----|------|
| Bundle ID | `com.lululabs.lulu` | Xcode + pubspec |
| Team ID | `F3GQ59884R` | Apple Developer |
| API Key (App Store Connect) | `FHY33UJUU2` | TestFlight 업로드용 |
| Issuer ID | `69a6de8c-25c7-47e3-e053-5b8c7c11a4d1` | `de8c` 주의 (`de96` 아님!) |
| P8 Key 경로 | `~/private_keys/AuthKey_FHY33UJUU2.p8` | altool 인증용 |
| IPA 빌드 경로 | `/Users/naezin/Desktop/LULU ver2/build/ios/ipa/Lulu.ipa` | 빌드 후 생성 |
| 메인 브랜치 | `main` (보호) | 직접 커밋 금지 |
| 작업 브랜치 패턴 | `sprint-XX` 또는 `sprint-XX-hotfix` | |
| debugPrint 태그 | `[OK]`, `[ERR]`, `[WARN]`, `[INFO]` | 이모지 대신 사용 |
| 앱스토어 이름 | 루루 | |

---

## 운영 매뉴얼 (복붙용 명령어)

> **사유**: 매 세션마다 명령어를 재구성하다 Issuer ID 오타 등 사고 발생.
> 아래 명령어를 **그대로 복사**해서 실행. 파라미터 수정 금지.

### TestFlight 업로드 (전체 플로우)

```bash
# 1. 버전 범프 (pubspec.yaml 수동 수정 후)
# version: X.Y.Z+BUILD_NUMBER

# 2. IPA 빌드
cd "/Users/naezin/Desktop/LULU ver2" && flutter build ipa --release

# 3. 업로드 (이 명령어 그대로 실행, 절대 변경 금지)
xcrun altool --upload-app --type ios \
  -f "/Users/naezin/Desktop/LULU ver2/build/ios/ipa/Lulu.ipa" \
  --apiKey FHY33UJUU2 \
  --apiIssuer 69a6de8c-25c7-47e3-e053-5b8c7c11a4d1
```

### Pre-commit Gate 에러 수정 패턴

```bash
# Gate 1 (한글): debugPrint 안의 한글 -> 영문으로
# Gate 2 (이모지): 아래 태그로 교체
#   [OK]  <- 성공 표시
#   [ERR] <- 에러 표시
#   [WARN] <- 경고 표시
#   [INFO] <- 정보 표시
#   [KEY] <- 키/인증 표시
# Gate 3 (Icons.): LuluIcons.xxx 로 교체
# Gate 4 (analyze): flutter analyze 에러 수정
# Gate 5 (print): print( -> debugPrint(
# Gate 6 (withOpacity): LuluColors에 솔리드 컬러 정의
```

### 커밋 명령어

```bash
# 작업 브랜치 확인
git branch --show-current

# 커밋 (HEREDOC 형식)
git commit -m "$(cat <<'EOF'
<type>(<scope>): <description>

<body>
EOF
)"
```

---

## 프로젝트 개요

**LULU** = AI 기반 스마트 육아 앱 (고위험 신생아 특화)

**포지셔닝**: "울음 분석으로 Hook → 조산아/다태아/SGA 특화로 Lock"
**슬로건**: "아기 울음을 AI가 통역해드려요. 쌍둥이도, 조산아도, 작게 태어난 아기도 완벽하게."
**미션**: "전 세계 모든 부모가 새벽 3시에도 한 손으로, 5초 안에, 아기의 다음 행동을 예측하고 안심할 수 있는 앱"

### 타겟 세그먼트 (36,500명/년)

| 세그먼트 | 연간 | 비율 |
|----------|------|------|
| 다태아 조산아 | 9,100 | 25% |
| 단태아 조산아 | 18,000 | 49% |
| 다태아 만삭 | 3,900 | 11% |
| 만삭 SGA | 5,500 | 15% |

### 핵심 수치

| 지표 | 값 |
|------|-----|
| 한국 출생/년 | 238,000 |
| LULU 타겟/년 | 36,500 (15.3%) |
| 다태아 중 조산율 | 70.8% |
| 조산아+다태아+SGA 전용 앱 | 0개 (100% Gap) |
| 목표 NPS | +66.7 |
| 목표 TSR | 92.5% |

### 경쟁 우위 (블루오션)

- 다태아 탭 전환 개별 추적: 경쟁앱 0개
- SGA 자동 감지: 경쟁앱 0개
- 조산아 교정연령 개별 계산: 최강
- Fenton/WHO 차트 자동 전환

### 비즈니스 모델 (Freemium)

| | Free | Premium |
|--|------|---------|
| 기록 | 5종 | 5종 |
| 아기 수 | 2명 | 4명 |
| 보관 | 7일 | 무제한 |
| 울음 분석 | 3회/일 | 무제한 |
| SGA | 기본 | Catch-up 트렌드 |

---

## 핵심 설계 원칙

1. **다태아 중심**: BabyTabBar 탭 전환, QuickRecordButton 원탭
2. **개별 교정연령**: 각 아기별 독립 계산 (GA 기반)
3. **3초 Rule**: 피로한 부모도 한 손으로 빠르게
4. **의료 정확성**: Fenton/WHO 차트, 출처 필수, 면책조항
5. **비교 금지**: 쌍둥이 우열 표현 절대 금지
6. **100% On-Device AI**: 오디오 서버 전송 X, 로컬 저장 X

---

## 기술 스택

| 영역 | 기술 |
|------|------|
| Frontend | Flutter 3.0+ (Dart SDK >=3.0.0 <4.0.0), Provider ^6.1.1 |
| Backend | Supabase (PostgreSQL + Auth + RLS + Storage) |
| AI | TFLite (울음 분석 83.6%, On-Device) |
| 인증 | Apple Sign-In, Email |
| 배포 | TestFlight (iOS) |
| 디자인 | Midnight Blue 테마 (Dark Mode First), Material Icons, Glassmorphism, 4px grid, 64x64dp Quick Action |

---

## Elite Agent Team (32명)

| 팀 | 인원 | 핵심 에이전트 |
|----|------|-------------|
| 경영/전략 | 4 | Product Strategist, Market Analyst, Business Modeler, PM |
| 제품/디자인 | 6 | UX Designer, UI Designer, Multiple Births, Mobile UX, Researcher, Auditor |
| 개발 | 7 | Flutter Architect, Flutter Dev, Backend, Supabase, QA, Security, System |
| 의료 | 8 | Neonatology, Pediatric, Sleep, Nutrition, Development, Physical, Clinical, Compliance |
| 마케팅 | 3 | Growth, Content Strategist, Creator |
| AI/ML | 5 | Audio ML, On-Device, Cry Research, Audio Privacy, Data Scientist |
| 글로벌 | 1 | Localization |

핵심: Multiple Births, Neonatology, Supabase Specialist

### 에이전트 상세 스펙

**경영/전략 (4명)**

| # | 에이전트 | 핵심 책임 |
|---|---------|----------|
| 1 | Product Strategist | 로드맵, MoSCoW 우선순위, 비전 |
| 2 | Market Analyst | TAM/SAM/SOM, 경쟁사 벤치마킹 |
| 3 | Business Modeler | Freemium 설계, Unit Economics |
| 4 | Project Manager | 일정, 리소스, 리스크 관리 |

**제품/디자인 (6명)**

| # | 에이전트 | 핵심 책임 |
|---|---------|----------|
| 5 | UX Designer | 3초 Rule, 플로우, 와이어프레임 |
| 6 | UI Designer | Midnight Blue 테마, 컴포넌트 |
| 7 | Multiple Births Specialist ⭐ | 탭 전환, 비교 금지, "둘 다" 검증 |
| 8 | Mobile UX Expert | 한 손 조작, 야간 사용성, 피로 대응 |
| 9 | User Researcher | 인터뷰, 페르소나, UT 설계 |
| 10 | Product Auditor | 일관성 검사, 릴리즈 검증 |

**개발 (7명)**

| # | 에이전트 | 핵심 책임 |
|---|---------|----------|
| 11 | Flutter Architect | Provider 패턴, 코드 구조 |
| 12 | Flutter Developer | 화면 구현, 위젯 개발 |
| 13 | Backend Developer | Auth, DB, Storage |
| 14 | QA Engineer | 테스트 케이스, 버그 추적 |
| 15 | Security Engineer | 암호화, GDPR, 데이터 보호 |
| 16 | System Architect | 확장성, 성능, 인프라 |
| 17 | Supabase Specialist ⭐ | MCP 검증, family_members 동기화, Apple Sign-In 대응 |

**의료/전문 (8명)**

| # | 에이전트 | 핵심 책임 |
|---|---------|----------|
| 18 | Neonatology Specialist ⭐ | 교정연령, Fenton, SGA 감지 |
| 19 | Pediatric Advisor | 발달 검증, 건강 가이드 |
| 20 | Sleep Specialist | Sweet Spot, 수면 패턴 |
| 21 | Nutrition Specialist | 수유 가이드, 영양 정보 |
| 22 | Developmental Lead | 발달 마일스톤, 놀이 가이드 |
| 23 | Physical Specialist | 터미타임, 운동 발달 |
| 24 | Clinical Data Analyst | WHO 차트, 의료 통계 검증 |
| 25 | Medical Compliance | 면책 조항, COPPA, 의료기기 규정 |

**마케팅 (3명)**: Growth Marketer, Content Strategist, Content Creator
**AI/ML (5명)**: Audio ML, On-Device ML, Cry Research, Audio Privacy, Data Scientist
**글로벌 (1명)**: Localization Lead (다국어, 문화 적응, i18n)

### Supabase Specialist 특별 규칙

미션: "RLS는 논리가 아닌 실행으로 검증한다"
Quality Gate: MCP-V1~V4 통과 + E2E 증거 필수
협업: Security Engineer (RLS 설계), Flutter Dev (동기화), QA (E2E)
담당: `supabase/migrations/*.sql`, `family_sync_service.dart`, `family_repository.dart`

---

## MVP-F 5종 기록

| 기록 | LuluIcons | 핵심 기능 | 조산아 고려 | SUS/TTC |
|------|-----------|----------|------------|---------|
| **수유** | `LuluIcons.feeding` | 모유(좌/우/양쪽), 분유, 혼합, ml 자유입력 | - | 84.6/2.54s |
| **수면** | `LuluIcons.sleep` | 낮잠/밤잠 자동 제안 (시간 기반) | - | 87.0/2.0s |
| **기저귀** | `LuluIcons.diaper` | 소변/대변, 색상 선택(선택적), 경고문 | 대변 색상 중요 | 85.4/1.74s |
| **놀이** | `LuluIcons.play` | 터미타임/목욕/외출/놀이/독서/기타 | 터미타임 권장시간 | 80+/<3s |
| **건강** | `LuluIcons.health` | 체온/증상/투약/병원방문, 면책 문구 | 조산아 체온 범위 | 80+/<3s |

공통: 3초 Rule, 개별 기록(탭 전환), QuickRecordButton("이전과 같이"), BabyTabBar(교정연령 통합)

### 건강 기록 체온 상태 표시

| 체온 | 상태 | 색상 | 메시지 |
|------|------|------|--------|
| <36.0°C | 저체온 | 파랑 | "체온이 낮아요. 보온에 신경써주세요." |
| 36.0-37.5°C | 정상 | 초록 | "정상 체온이에요." |
| 37.5-38.0°C | 미열 | 노랑 | "미열이 있어요. 지켜봐주세요." |
| >38.0°C | 발열 | 빨강 | "열이 있어요. 병원 방문을 권장해요." |

의료 면책: "이 정보는 참고용이며 의료 조언이 아닙니다."

---

## DB 스키마

```
families (1)
├── family_members (N)
│   ├── user_id: UUID (auth.users FK)
│   ├── role: 'owner' | 'member'
│   └── UNIQUE(family_id, user_id)
├── family_invites (N)     ← 초대 코드 (6자리, 7일 유효)
├── babies (N)
│   └── activities (N)     ← 5종 기록
└── user_id               ← 레거시 호환용 (직접 사용 금지)
```

### RLS 정책 (12개)

activities(4) + babies(4) + families(4) — 모두 `is_family_member_or_legacy()` 기반

### RLS 영향도 높은 파일

| 파일 | 영향도 |
|------|--------|
| `main.dart` (OnboardingWrapper) | 🔴 |
| `family_sync_service.dart` | 🔴 |
| `family_repository.dart` | 🔴 |
| `003_family_sharing.sql` | 🔴 Critical |
| `record_provider.dart` | 🟡 |
| `home_provider.dart` | 🟡 |

### 함수 (7개)

`is_family_member`, `is_family_owner`, `is_family_member_or_legacy`, `create_family_with_babies`, `get_family_info`, `accept_invite`, `on_family_created` (Trigger)

---

## 데이터 모델

```dart
/// 가족 모델 - 최상위 컨테이너
class FamilyModel {
  final String id;
  final String name;
  final List<BabyModel> babies;  // 1-4명
  final DateTime createdAt;
  BabyModel? get activeBaby;
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

  int? get correctedAgeInWeeks {
    if (gestationalWeeks == null || gestationalWeeks! >= 37) return null;
    final actualDays = DateTime.now().difference(birthDate).inDays;
    final correctionDays = (40 - gestationalWeeks!) * 7;
    return ((actualDays - correctionDays) / 7).floor();
  }
  bool get isPreterm => gestationalWeeks != null && gestationalWeeks! < 37;
}

/// 활동 기록 - 개별 아기 기록
class ActivityModel {
  final String id;
  final String babyId;
  final ActivityType type;
  final DateTime startTime;
  final DateTime? endTime;
  final Map<String, dynamic>? data;
}

enum BabyType { singleton, twin, triplet, quadruplet }
enum ActivityType { sleep, feeding, diaper, play, health }
```

---

## Icons 매핑 (활동 5종 + 성장 3종)

| 용도 | LuluIcons | 실제 Icon | 색상 |
|------|-----------|-----------|------|
| 수면 | `LuluIcons.sleep` | `Icons.bedtime_rounded` | `LuluActivityColors.sleep` |
| 수유 | `LuluIcons.feeding` | `Icons.local_drink_rounded` | `LuluActivityColors.feeding` |
| 기저귀 | `LuluIcons.diaper` | `Icons.baby_changing_station_rounded` | `LuluActivityColors.diaper` |
| 놀이 | `LuluIcons.play` | `Icons.toys_rounded` | `LuluActivityColors.play` |
| 건강 | `LuluIcons.health` | `Icons.favorite_rounded` | `LuluActivityColors.health` |
| 체중 | - | `Icons.monitor_weight_rounded` | secondary |
| 신장 | - | `Icons.straighten_rounded` | secondary |
| 두위 | - | `Icons.psychology_rounded` | secondary |

**반드시 `LuluIcons.xxx`로 참조. `Icons.xxx` 직접 사용 금지 (lulu_icons.dart 내부 제외).**
전체 아이콘 목록은 위 "디자인 시스템 > Icons 매핑 (v7.3 업데이트)" 참조.

---

## 색상 매핑

| 용도 | 변수명 | 색상 코드 | 비고 |
|------|--------|-----------|------|
| 밤잠 | `LuluColors.nightSleep` | `#5B5381` | 어두운 보라 (솔리드) |
| 낮잠 | `LuluColors.daySleep` | `#9D8CD6` | 밝은 보라 (솔리드, NEW) |
| 수유 | `LuluActivityColors.feeding` | `#E8A838` | 오렌지 |
| 기저귀 | `LuluActivityColors.diaper` | `#4A90D9` | 블루 |
| 놀이 | `LuluActivityColors.play` | `#6BC48A` | 그린 |
| 건강 | `LuluActivityColors.health` | `#E57373` | 레드 |

**`withOpacity()` / `withValues(alpha:)` 로 색상 만들기 금지. 솔리드 컬러를 LuluColors에 정의해서 사용.**

---

## 디자인 시스템 (v7.3 업데이트)

### 컴포넌트 레이어

| 컴포넌트 | 클래스 | 용도 | 채택률 |
|----------|--------|------|--------|
| 색상 | `LuluColors` | 기본 색상 + 솔리드 토큰 26개 | 100% |
| 활동 색상 | `LuluActivityColors` | 5종 활동별 색상 | 100% |
| 패턴 색상 | `LuluPatternColors` | 차트/패턴 전용 | 100% |
| 텍스트 | `LuluTextStyles` | 타이포그래피 | 100% |
| 간격 | `LuluSpacing` | 4px 그리드 기반 | — |
| 모서리 | `LuluRadius` | BorderRadius 토큰 | 99% |
| 그림자 | `LuluShadows` | BoxShadow 토큰 | 100% |
| 아이콘 | `LuluIcons` | Material Icons 래퍼 (168개, 전체 rounded) | 100% |

### 아이콘 스타일 규칙

**전체 168개 아이콘 `_rounded` 통일** (v7.3 확정)
- `_outlined` (non-rounded) 스타일 금지
- 신규 아이콘 추가 시 반드시 `_rounded` 사용
- 커스텀 SVG 아이콘: `assets/icons/` 디렉토리 + `SvgPicture.asset` 사용

### Icons 매핑 (v7.3 업데이트)

| 용도 | LuluIcons | 실제 Icon | 색상 |
|------|-----------|-----------|------|
| 수면 | `LuluIcons.sleep` | `Icons.bedtime_rounded` | `LuluActivityColors.sleep` |
| 수유 | `LuluIcons.feeding` | `Icons.local_drink_rounded` | `LuluActivityColors.feeding` |
| 기저귀 | `LuluIcons.diaper` | `Icons.baby_changing_station_rounded` | `LuluActivityColors.diaper` |
| 놀이 | `LuluIcons.play` | `Icons.toys_rounded` | `LuluActivityColors.play` |
| 건강 | `LuluIcons.health` | `Icons.favorite_rounded` | `LuluActivityColors.health` |
| 대변 | `LuluIcons.poop` | 커스텀 SVG (`assets/icons/poop.svg`) | `LuluActivityColors.diaper` |
| 트로피 | `LuluIcons.trophy` | `Icons.emoji_events_rounded` | — |
| 뱃지 | `LuluIcons.badge` | `Icons.workspace_premium_rounded` | — |

---

## 수면 중복 처리 규칙 (v7.3 신설)

| 시나리오 | 동작 |
|----------|------|
| 수면 진행 중 + 다른 활동 (수유/기저귀/놀이) | 허용 (수면 계속) |
| 수면 진행 중 + 새 수면 "지금 재우기" (같은 아기) | **확인 다이얼로그** ("이전 수면 종료 + 새로 시작" / "취소") |
| 수면 진행 중 + 과거 수면 추가 (같은 아기, 겹침) | 허용 + **경고 토스트** (차단 아님) |
| 수면 진행 중 + 다른 아기 수면 | 허용 (충돌 아님) |

**근거**: 실수로 탭 시 수면 기록 복구 불가. 조산아 부모에게 수면 기록은 의료 보고용 → 데이터 안전 > 3초 Rule

---

## 저장 토스트 규칙 (v7.3 신설)

```
FAB/QuickRecord 저장 완료
  → 홈 유지
  → "저장됨    기록 보기 >" SnackBar (2초)
  → "기록 보기" 탭 → Records Daily 이동
  → 무시 → 2초 후 자동 사라짐
  → 새 기록 저장 시 → 이전 SnackBar 즉시 교체
```

---

## 스와이프 액션 규칙 (v7.3 신설)

- 힌트 ("Swipe to edit/delete"): **최초 3회만 표시** (SharedPreferences 카운터)
- Edit/Delete 버튼: **아이콘만** (텍스트 제거 — 줄바꿈 방지)

---

## Provider 아키텍처 (v7.3 업데이트)

### 전역 등록 (main.dart MultiProvider)

```
1. AuthProvider
2. HomeProvider
3. RecordProvider
4. OngoingSleepProvider
5. SettingsProvider
6. CryAnalysisProvider
7. FamilyProvider
8. BadgeProvider (Sprint 22 추가)
```

### 화면 로컬 생성 (전역 등록 불가)

```
PatternDataProvider — Daily/Weekly에서 다른 상태로 사용 (단일 인스턴스 불가)
StatisticsDataProvider — 주간 날짜범위/필터 상태 종속
GrowthProvider — 성장 화면 lifecycle 종속
```

**상태 동기화 패턴**: `context.watch<HomeProvider>()` + `_previousBabyId` 추적으로 baby 변경 감지 → 리로드

---

## Supabase 레이어 격리 (v7.3 신설)

### 계층 구조

```
Screen/Widget → Provider → Repository → Supabase
                          → SupabaseService (auth 읽기 전용)
```

### 규칙
- **Provider/Screen/Widget에서 `Supabase.instance.client` 직접 호출 금지** → Repository 경유
- **auth 읽기**: `SupabaseService.currentUserId`, `SupabaseService.currentUser`
- **서비스 레이어 예외**: `invite_service.dart`, `supabase_service.dart`, `main.dart` 등은 Supabase 직접 호출 허용 (인프라/서비스 레이어)

---

## 다태아 UX 원칙

### 필수 vs 금지

| ✅ 필수 | ❌ 금지 |
|---------|---------|
| 개별 기록 (탭 전환) | "둘 다" 버튼 |
| 비교 금지 UX | 동시 기록 UI |
| 교정연령 개별 계산 | 쌍둥이 비교 표현 |
| 빠른 탭 전환 (< 1초) | BabySelector 사용 |
| QuickRecordButton | selectedBabyId = null |
| 탭에 교정연령 통합 | "A가 B보다 많이" 표현 |

### "둘 다" 버튼 제거 (v5.0 확정)

제거됨: BabyTabBar "둘 다" 옵션, BabySelector 컴포넌트, 동시 기록 기능, selectedBabyId=null 로직
대안: 빠른 탭 전환(원탭 <1초), QuickRecordButton("이전과 같이" 원탭 저장), 개별 기록 후 순차 전환

| 적용 파일 | 상태 |
|----------|------|
| QuickRecordButton 생성 | ✅ |
| FeedingRecordScreen → BabyTabBar + QuickRecordButton | ✅ |
| SleepRecordScreen | ✅ |
| DiaperRecordScreen | ✅ |
| PlayRecordScreen | ✅ |
| HealthRecordScreen | ✅ |
| BabySelector 삭제 | ✅ |
| GrowthInputScreen → BabyTabBar | ✅ |

---

## UX 확정 시안

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

### 메인 화면 구조 (v5.1)

```
┌─────────────────────────────────────────┐
│ [하늘이 교정42일] [바다 교정38일]       │ ← BabyTabBar (교정연령 통합)
├─────────────────────────────────────────┤
│ 수면 2h전 | 수유 30m전 | 기저귀 1h전    │ ← LastActivityRow
├─────────────────────────────────────────┤
│ SweetSpotCard (예측 + 수면중 상태)      │ ← OngoingSleepCard 통합
├─────────────────────────────────────────┤
│              [+] FAB                    │ ← QuickActionGrid 대체
└─────────────────────────────────────────┘
```

### 기록 화면 공통 구조 (v5.0)

```
┌─────────────────────────────────────────┐
│ ← [수유 기록]                           │ ← AppBar
├─────────────────────────────────────────┤
│ [하늘이] [바다]                         │ ← BabyTabBar
├─────────────────────────────────────────┤
│ 이전과 같이: 분유 120ml                 │ ← QuickRecordButton
├─────────────────────────────────────────┤
│ [상세 입력 폼]                          │
├─────────────────────────────────────────┤
│ [저장]                                  │
└─────────────────────────────────────────┘
```

---

## 기록 탭 아키텍처

### 현재 상태: `a2f1ca2` (Sprint 17.5 + 18.5 + 18-R HF)

```
RecordHistoryScreen
├── AppBar: "기록"
├── BabyTabBar (다태아 시)
├── ScopeToggle (일간/주간)
├── DailyView
│   ├── DateNavigator
│   ├── MiniTimeBar (24h 시각화, 48슬롯)
│   ├── DailySummaryBanner
│   └── ActivityList
└── WeeklyView
    ├── DateNavigator
    ├── TimelineFilterChips
    └── WeeklyPatternChart (7일 히트맵, v4.1)
```

### 타겟 구조 (Sprint 19)

```
RecordHistoryScreen
├── AppBar: "기록"
├── BabyTabBar (다태아 시)
├── ScopeToggle (일간/주간)
├── DailyView
│   ├── DateNavigator
│   ├── DailyGrid (2x2: 수면/수유/기저귀/놀이)  ← NEW
│   └── ActivityList
└── WeeklyView
    ├── DateNavigator
    ├── FilterChips → WeeklyChartFull 연동        ← NEW
    ├── WeeklyChartFull (7일×24h 실시간 차트)     ← NEW
    ├── WeeklyGrid (2x2, DailyGrid와 동일 레이아웃) ← NEW
    └── WeeklyInsight (교정연령 기반 인사이트)     ← NEW
```

**삭제 대상**: MiniTimeBar, DailySummaryBanner, ContextRibbon, ElapsedTimeIndicator, TimelineFilterChips(일간), WeeklyPatternChart

---

## 프로젝트 구조

```
lib/
├── core/
│   ├── design_system/
│   │   ├── lulu_colors.dart           ← Midnight Blue 테마
│   │   ├── lulu_icons.dart            ← LuluIcons 클래스
│   │   └── lulu_typography.dart
│   └── utils/
│       ├── corrected_age_calculator.dart
│       └── sleep_type_suggester.dart
├── features/
│   ├── auth/
│   ├── onboarding/
│   ├── home/
│   │   ├── screens/home_screen.dart
│   │   ├── providers/home_provider.dart     ← 캐싱 최적화
│   │   └── widgets/
│   │       ├── today_summary_card.dart
│   │       ├── sweet_spot_hero_card.dart    ← deprecated (SweetSpotCard 사용)
│   │       └── cry_analysis_placeholder.dart ← Phase 2 예약
│   ├── settings/
│   │   ├── screens/settings_screen.dart
│   │   └── providers/settings_provider.dart
│   ├── record/
│   │   └── screens/
│   │       ├── feeding_record_screen.dart
│   │       ├── sleep_record_screen.dart
│   │       ├── diaper_record_screen.dart
│   │       ├── play_record_screen.dart
│   │       └── health_record_screen.dart
│   ├── timeline/
│   │   ├── models/daily_pattern.dart
│   │   ├── providers/pattern_data_provider.dart
│   │   └── widgets/
│   │       ├── activity_list_item.dart      ← 스와이프 삭제/편집
│   │       ├── daily_summary_banner.dart
│   │       ├── date_navigator.dart
│   │       ├── edit_activity_sheet.dart
│   │       ├── mini_time_bar.dart
│   │       ├── statistics_tab.dart
│   │       ├── timeline_tab.dart
│   │       ├── weekly_pattern_chart.dart
│   │       └── widgets.dart
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
        ├── sweet_spot_card.dart        ← OngoingSleepCard 통합
        ├── last_activity_row.dart
        ├── quick_record_button.dart
        ├── undo_delete_mixin.dart      ← 5초 실행취소
        └── mini_timeline.dart
```

삭제된 파일: `quick_action_grid.dart` (→FAB), `ongoing_sleep_card.dart` (→SweetSpotCard), `baby_selector.dart` (→BabyTabBar)

---

## 코딩 컨벤션

### 절대 규칙 7개 (v7.3 업데이트, 위반 시 커밋 차단)

```
1. ❌ 이모지 금지      → ✅ LuluIcons만 (debugPrint 내부도 영문 태그 사용)
2. ❌ 하드코딩 한글 금지 → ✅ ARB/AppLocalizations 경유 (i18n 필수)
3. ❌ print문 금지      → ✅ debugPrint 사용
4. ❌ 빈 catch 금지     → ✅ 에러 처리 또는 로깅
5. ❌ withOpacity 금지  → ✅ withValues(alpha:) 또는 솔리드 컬러 (LuluColors에 정의)
6. ❌ BabySelector 금지 → ✅ BabyTabBar 사용
7. ❌ Icons.xxx 직접 사용 금지 → ✅ LuluIcons.xxx (lulu_icons.dart 내부 제외)
```

### Pre-commit Hook (6/6 게이트)

```bash
# .git/hooks/pre-commit
# GATE 1: 하드코딩 한글 → 차단
# GATE 2: 이모지 → 차단
# GATE 3: Icons. 직접 사용 → 차단 (오탐 방지: [^a-zA-Z]Icons\. + grep -v LuluIcons)
# GATE 4: flutter analyze 에러 → 차단
# GATE 5: print문 → 차단
# GATE 6: withOpacity → 차단
```

**`--no-verify`로 우회 절대 금지.**

---

## Confidence Score (v7.4 신설)

> **Sprint 18 롤백 교훈**: "수정했습니다"라는 보고만으로는 실제 확인 여부를 판단할 수 없었음

### 규칙

모든 보고(Phase 완료, 버그 수정, 상태 확인)에 **Confidence Score**를 포함한다.

**형식**: `N/10 [근거]`

| 점수 | 의미 | 근거 예시 |
|------|------|-----------|
| **10/10** | 실행 확인 완료 | `[시뮬레이터 실행 + 스크린샷]` |
| **9/10** | 코드 실행 확인 | `[flutter run 성공 + 해당 화면 진입]` |
| **8/10** | 코드 확인 완료 | `[파일 열어서 변경 확인 + analyze 통과]` |
| **7/10** | 코드 리뷰 기반 | `[코드 읽었으나 실행 미확인]` |
| **6/10** | 패턴 기반 추론 | `[유사 코드 패턴 확인, 해당 파일 미확인]` |
| **5/10 이하** | 추측 | `[코드 미확인, 구조 기반 추론]` |

### 사용 예시

```
## FIX-01: SnackBar dismiss 버그
- 상태: 수정 완료
- Confidence: 9/10 [flutter run 성공 + 홈에서 기록 저장 후 SnackBar 동작 확인]

## FIX-02: Provider 동기화
- 상태: 수정 완료
- Confidence: 7/10 [코드 변경 확인했으나 다태아 전환 시나리오 미실행]
```

### 승인 기준

| 작업 유형 | 최소 Confidence | 비고 |
|----------|----------------|------|
| TestFlight 배포 전 | **9/10 이상** | 실행 확인 필수 |
| Phase 완료 보고 | **8/10 이상** | 코드 확인 필수 |
| 분석/제안 | **6/10 이상** | 추론 허용, 명시 필수 |

---

## Scope Declaration (v7.4 신설)

> **Sprint 18 사고**: 28개 파일 동시 변경 중 범위가 불명확하여 의도치 않은 파일까지 수정됨

### 규칙

모든 작업지시서 및 Round 수정 보고 시 **Scope Declaration**을 포함한다.

**형식**:

```
## Scope Declaration

수정 대상:
- lib/features/home/widgets/sweet_spot_card.dart (L45~72)
- lib/l10n/app_ko.arb (키 2개 추가)

제외 (건드리지 않음):
- lib/features/home/home_screen.dart -- 이미 정상 동작
- lib/features/records/ -- 이번 작업 범위 밖

나중에 (발견했지만 지금 안 함):
- sleep_record_card.dart L88: deprecated API 사용 -> Sprint 21에서 처리
```

### 필수 포함 항목

| 카테고리 | 내용 | 목적 |
|----------|------|------|
| **수정** | 파일 경로 + 라인 범위 (가능 시) | 변경 범위 명확화 |
| **제외** | 건드리지 않는 파일/모듈 + 이유 | 의도치 않은 수정 방지 |
| **나중에** | 발견한 이슈 + 처리 시점 | 기술 부채 추적 |

### 적용 시점

- 작업지시서 작성 시: 작성자가 Scope 선언
- 딥다이브 분석 보고 시: 실제 코드 확인 후 Scope 갱신
- Phase/Group 완료 보고 시: 최종 Scope 확인

---

### 커밋/버전 규칙

```
<type>(<scope>): <description>
Types: feat, fix, refactor, style, docs, test
Scopes: onboarding, multiple, preterm, record, dashboard, widget, chart
Major.Minor.Patch+Build
```

### 커밋 타이밍 규칙 (2026-02-08 신설)

> **사유**: Sprint 19에서 Claude Code가 여러 Phase를 커밋 없이 진행 → 롤백 시 복구 지점 부재.

```
1. Phase 완료 시 반드시 커밋
   - Phase 검증 통과 → 즉시 커밋 → 보고
   - 커밋 없는 Phase 완료 보고는 미완료 처리

2. 커밋 메시지에 Phase 번호 포함
   - feat(record): Sprint 19 Phase 1 - DayTimeline model
   - fix(chart): Sprint 19 Phase 3 - overnight clamping

3. 장시간 작업 시 중간 커밋
   - 1시간 이상 연속 작업 시 중간 커밋 권장
   - "작동하는 상태"에서 커밋 (빌드 깨진 상태 커밋 금지)
```

### 브랜치 전략

```
main (보호) ← 실기기 확인 후에만 머지
  └── sprint-XX (작업 브랜치)
       ├── Phase 1 커밋 → 검증 → ✅
       ├── Phase 2 커밋 → 검증 → ✅
       └── 전체 완료 + 실기기 확인 → main 머지
```

---

## Flutter 레이아웃 규칙 (2026-02-08 신설)

> **사유**: Sprint 19 차트 사고. CustomPaint + Column 중첩에서 intrinsic height 계산 실패.
> 7회 이상 시도, 12시간 소요. 구조 변경으로 즉시 해결.

### CustomPaint 규칙

```dart
// ❌ 금지: Column 안에 CustomPaint (intrinsic height = 0)
Column(
  mainAxisSize: MainAxisSize.min,
  children: List.generate(7, (i) =>
    Row(children: [
      Expanded(child: CustomPaint(size: Size.infinite)),  // height 0 보고
    ]),
  ),
);

// ✅ 올바른 방법: 단일 CustomPaint + 고정 SizedBox
SizedBox(
  height: 7 * 28.0,  // 고정 높이
  child: CustomPaint(
    size: Size(double.infinity, 7 * 28.0),
    painter: MyGridPainter(),  // paint()에서 for 루프로 7행 직접 그림
  ),
);
```

**핵심**: 반복 렌더링은 Column/Row가 아니라 **Canvas에서 for 루프**로 직접 그려라.

### async/await 체인 규칙

```dart
// ❌ 금지: await 누락 (데이터 로드 전 setState 호출됨)
void _navigate() {
  _provider.goToNext();    // Future 버림!
  setState(() {});          // 빈 데이터로 rebuild
}

// ✅ 올바른 방법: 체인 전체에 async/await
Future<void> _navigate() async {
  await _provider.goToNext();
  if (mounted) setState(() {});
}
```

**규칙**: Future 반환 함수 호출 시 await 안 쓸 이유가 없으면 무조건 await.

### 3회 실패 룰

```
같은 접근으로 3번 실패 → 파라미터 튜닝 중단 → 구조 변경 보고

❌ 4번째도 같은 구조에서 파라미터만 조정
✅ "동일 접근 3회 실패. 구조 [X]가 근본 원인. 변경 방안: [A] vs [B]. 어느 것으로?"
```

---

## 작업 행동 규칙 (2026-02-08 신설)

> **사유**: Claude Code가 지시된 코드를 "개선"한다고 변형 → 반복적 버그 발생.

### 규칙 1: "수정됨" 보고 금지 → "확인됨" 보고만 허용

```
❌ "clampToDay를 수정했습니다"
✅ "clampToDay 수정 후 시뮬레이터에서 밤잠이 0시부터 표시됩니다 [스크린샷]"
```

**코드 변경은 과정이지 결과가 아니다. 화면에서 확인된 것만 결과다.**

### 규칙 2: 지시된 코드를 변형하지 마라

```
❌ "지시하신 코드를 기반으로 개선하여 적용했습니다"
✅ "지시하신 코드를 그대로 적용했습니다. [X]가 추가로 필요해 보이는데 수정해도 될까요?"
```

변형이 필요하면 **먼저 보고하고 승인** 받아라. 임의 변형 금지.

### 규칙 3: 디버그 시각화 먼저

```dart
// 1. 영역 확인
Container(color: Colors.red, child: 문제위젯)
// 2. 데이터 확인
debugPrint('data.length=${data.length}');
// 3. 빌드 확인
debugPrint('build: ${widget.runtimeType}');
```

**"이게 원인일 것 같다"로 수정하지 마라. 디버그 시각화로 확인 후 수정.**

### 규칙 4: 해결 완료된 코드 건드리지 마라

스크린샷으로 확인된 해결 항목은 이후 작업에서 절대 변경 금지:

```
현재 건드리면 안 되는 것 (Sprint 19 기준):
- weekly_chart_full.dart의 _WeeklyGridPainter 구조
- _navigateWeek의 async/await 구조
- goToPreviousWeek/goToNextWeek의 await
- 1행 1줄 덮어그리기 렌더링 방식
```

---

## 작업 완료 원칙 (Completion Policy)

- 작업 크기/시간보다 **완성도**가 훨씬 중요
- 작업지시서 = 계약서 (임의 수정 불가)
- 100% 완료 전까지 "완료" 선언 금지

**절대 금지**:
- 작업지시서 항목을 임의로 보류/축소/연기
- "나중에", "추후에", "Phase X에서" 등으로 범위 축소
- 의존성을 이유로 한 부분 완료 선언
- 임의 판단으로 작업 스킵

**필수 준수**:
- 모든 Step은 100% 완료 후 다음 Step 진행
- 막히면 "막혔다"고 보고 (임의 스킵 금지)
- 레거시 삭제 = 의존 파일 마이그레이션 포함
- 체크박스 전부 완료 전 Step 완료 선언 금지

---

## Phase별 검증 게이트 (2026-02-06 신설, 절대 생략 금지)

> **사유**: Sprint 18-R + 19 전체 롤백 사고.
> "빌드 성공, 에러 0개" 보고 후 실기기에서 버그 11건 발견.

### 규칙

```
1. 한 Phase 완료 → 검증 스크립트 실행 → 시뮬레이터 스크린샷 → 보고
2. 스크린샷 없는 "완료" 보고는 완료로 인정하지 않는다
3. 다음 Phase는 이전 Phase 승인 후에만 진행한다
4. "빌드 성공"만으로 완료 판단하지 않는다
5. 절대 Phase 전체를 한 번에 하지 않는다
```

### Phase 완료 보고 형식 (필수)

```
Phase N 완료 보고

1. 변경 파일: [목록]
2. flutter analyze: 에러 0개
3. 시뮬레이터 스크린샷: [첨부 필수]
4. 검증 스크립트 결과:
   - 하드코딩 한글: 0건
   - Icons. 직접 사용: 0건
   - i18n 사용: N건
   - 레거시 위젯 참조: 0건
   - 이모지: 0건
   - print문: 0건
```

### Phase 완료 검증 스크립트 (매 Phase 실행 필수)

```bash
#!/bin/bash
echo "=== Phase 완료 검증 ==="
FILES="[이번 Phase에서 변경한 파일 목록]"

echo "1. 하드코딩 한글"
for f in $FILES; do
  grep -nP '[\x{AC00}-\x{D7A3}]' "$f" 2>/dev/null | grep -v '//\|///\|debugPrint' || true
done

echo "2. Icons. 직접 사용 (lulu_icons.dart 제외)"
for f in $FILES; do
  grep -n 'Icons\.' "$f" 2>/dev/null | grep -v '//\|lulu_icons' || true
done

echo "3. i18n 사용 확인"
for f in $FILES; do
  grep -c 'AppLocalizations\|localizations\|\.tr\b' "$f" 2>/dev/null || echo "0"
done

echo "4. 레거시 위젯 참조"
grep -rn 'MiniTimeBar\|ContextRibbon\|LastActivityBadges\|WeeklyPatternChart\|BabySelector\|DailySummaryBanner\|ElapsedTimeIndicator' $FILES 2>/dev/null || echo "0건"

echo "5. 이모지"
for f in $FILES; do
  grep -nP '[\x{1F300}-\x{1F9FF}\x{2600}-\x{26FF}]' "$f" 2>/dev/null | grep -v '//' || true
done

echo "6. print문"
for f in $FILES; do
  grep -n '^\s*print(' "$f" 2>/dev/null | grep -v 'debugPrint\|//' || true
done

echo "7. flutter analyze"
flutter analyze 2>&1 | tail -3
```

---

## 작업지시서 필수 포함 사항

> **사유**: Claude Code가 작업지시서를 자의적으로 해석해서 2x2를 1x3으로, LuluIcons를 Icons로, i18n을 하드코딩으로 구현.

### 모든 신규 위젯 지시 시 반드시 포함

```
1. 정확한 import 경로 명시
2. i18n 키 예시: AppLocalizations.of(context)!.keyName
3. LuluIcons 매핑 예시: LuluIcons.sleep (Icons.bedtime_rounded 아님)
4. 삭제 대상 명시적 나열 (파일명 + line 범위 + grep 확인 커맨드)
5. 금지 패턴 vs 올바른 패턴 코드 예시:
```

```dart
// ❌ 절대 금지
Text('수면'),                              // 하드코딩 한글
Icon(Icons.bedtime_rounded),               // Icons 직접 사용
color.withOpacity(0.5),                    // opacity
print('debug');                            // print

// ✅ 반드시 이렇게
Text(AppLocalizations.of(context)!.sleep), // i18n
Icon(LuluIcons.sleep),                     // LuluIcons
LuluColors.daySleep,                       // 솔리드 컬러
debugPrint('debug');                       // debugPrint
```

### 작업지시서 템플릿 v2.1 (v7.4 신설)

#### 블록 1: 안전 체크

작업 시작 전 반드시 확인:
- 현재 브랜치 확인 (`git branch --show-current`)
- 마지막 커밋 확인 (`git log --oneline -3`)
- 작업 대상 파일 백업 커밋 존재 여부

**Slop Detection 테이블**:

| 패턴 | 대응 |
|------|------|
| "수정했습니다" (스크린샷 없음) | Confidence Score 요구 |
| "문제없을 것 같습니다" | 실행 확인 요구 |
| "이전과 동일하게 처리했습니다" | 해당 파일 실제 확인 요구 |
| "완료입니다" (체크리스트 없음) | Verification Loop 요구 |

#### 블록 2: 작업 실행

작업지시서의 각 Step을 순서대로 100% 완료 후 다음 Step 진행.

#### 블록 3: 딥다이브

```
1단계: 현상 파악 (무엇이 잘못되었나)
2단계: 근본 원인 분석 (왜 발생했나)
3단계: Scope Declaration
   - 수정 대상: 파일 경로 + 라인 범위
   - 제외 (건드리지 않음): 파일 경로 + 이유
   - 나중에 (발견했지만 지금 안 함): 이슈 설명 + 처리 시점
4단계: 제안 (어떻게 고칠 것인가)
5단계: 승인 대기 (임의 수정 금지)
```

#### 블록 4: Verification Loop (v2.1 신설)

Phase/Group/FIX 완료 시 아래 체크리스트를 보고에 포함:

```
Verification Loop
-----------------
[ ] flutter analyze: 에러 0개
[ ] Pre-commit Gate: 6 Gate 통과
[ ] 변경 파일 목록: [나열]
[ ] 하드코딩 한글: 0건
[ ] Icons. 직접 사용: 0건
[ ] 이모지: 0건
[ ] print문: 0건
[ ] Confidence Score: N/10 [근거]
```

**규칙**: 전항목 PASS + Confidence 8/10 이상이어야 다음 Phase 승인 요청 가능.

---

## 금지 사항 (종합)

### 코드
- 하드코딩 API 키, print문, 빈 catch, TODO 없이 임시 코드, 강제 언래핑(!!)
- BabySelector 사용, family_members INSERT 누락, 이모지, withOpacity, Icons.xxx 직접 사용

### UX
- "둘 다" 버튼, 쌍둥이 우열 비교, "정상/비정상" 판단, 의료 진단/치료 표현, 3초 초과 핵심 동작

### 의료
- "진단합니다/치료합니다", 의료기기 암시, 출처 없는 의학 수치

---

## RLS 에러 재발 방지 가이드 (Critical!)

**근본 원칙**: "데이터 존재" ≠ "현재 사용자의 데이터 존재". RLS는 "권한"을 검증 (auth.uid() 기준)

**실수 패턴 (11회 반복됨)**:
1. families INSERT 후 family_members INSERT 누락
2. "데이터 있음" 확인만 하고 "권한 있음" 확인 안 함
3. Apple Sign-In 재설치 시 uid 변경 미고려

### RLS 작업 체크리스트 (필수)

```
□ family_members INSERT 누락 없음
  └ families INSERT 후 반드시 family_members에도 INSERT

□ auth.uid()와 family_members 매칭 확인
  └ MCP 쿼리: SELECT au.id, fm.user_id FROM auth.users au LEFT JOIN family_members fm ON fm.user_id = au.id

□ is_family_member_or_legacy() 테스트
  └ MCP 쿼리: SELECT is_family_member_or_legacy('<family_id>')

□ 실제 앱에서 기록 저장 테스트
  └ 수유/수면/기저귀 중 최소 1개 저장 성공 + RLS 에러 없음

□ Apple Sign-In 특이사항 인지
  └ 앱 재설치 시 새 uid 생성 → main.dart 로컬 복원 시 family_members upsert 필수
```

---

## TestFlight 빌드 가이드

1. **Info.plist 수출규정 면제** (필수): `ITSAppUsesNonExemptEncryption` = `false`
2. **빌드**: `flutter build ipa --release`
3. **업로드** (아래 명령어 그대로 실행, 절대 변경 금지):

```bash
xcrun altool --upload-app --type ios \
  -f "/Users/naezin/Desktop/LULU ver2/build/ios/ipa/Lulu.ipa" \
  --apiKey FHY33UJUU2 \
  --apiIssuer 69a6de8c-25c7-47e3-e053-5b8c7c11a4d1
```

4. **버전**: `pubspec.yaml`의 `version: X.Y.Z+BUILD_NUMBER` 업데이트 필수

### App Store Connect 인증 (절대 잊지 말 것)

| 항목 | 값 |
|------|-----|
| API Key | `FHY33UJUU2` |
| Issuer ID | `69a6de8c-25c7-47e3-e053-5b8c7c11a4d1` |
| Key 파일 | `~/private_keys/AuthKey_FHY33UJUU2.p8` |
| Bundle ID | `com.lululabs.lulu` |
| Team ID | `F3GQ59884R` |

---

## Phase/Sprint 체계

### Phase (제품 로드맵)

| Phase | 시기 | 목표 | 핵심 기능 |
|-------|------|------|----------|
| **Phase 1** | Q1 2026 | MVP-F | 5종 기록 + 다태아 + 조산아 |
| **Phase 2** | Q2 2026 | AI 울음 | 울음 분석 + 패턴 학습 |
| **Phase 3** | Q3 2026 | 워치 | Apple Watch 연동 |
| **Phase 4** | Q4 2026 | AI 통합 | 예측 + 코칭 |

### Sprint 이력

| Sprint | 내용 | 상태 |
|--------|------|------|
| 1-6 | MVP Core (모델, 온보딩, 다태아 UI, 조산아, UX, 구현) | ✅ |
| 7-8 | 홈개선, 설정, SGA, i18n, CSV 내보내기 | ✅ |
| 9-10 | 울음분석 AI (TFLite 442KB, 83.6%, Dunstan 5타입) | ✅ |
| 11-15 | TestFlight, 인증(Apple+Email), Import, 가족공유, 버그수정 | ✅ |
| 16 | Family Sharing v3.2 (RLS 12개, family_members, 초대코드) | ✅ |
| 17 | 기록 히스토리 v1.1 (DateNavigator, MiniTimeBar, WeeklyPatternChart) | ✅ |
| 17.5 | Timeline/Statistics 대규모 개선 | ✅ |
| 17.6 | Hotfix 3건 (Import, MiniTimeBar, 통계) | ✅ |
| 18.5 | WeeklyPatternChart v4.1 세로 전환 | ✅ |
| 18 | Timeline 위젯 재작성 시도 | 🔴 사고 → 복원 |
| 18-UX | 기록탭 UX 프로세스 (디자인/프로토타입) | ✅ |
| 18-R | 기록탭 재건 + HF | 🔴 **롤백 (규칙 위반)** |
| **19** | **차트 재설계 (재작업)** | ✅ |
| **20-HF** | **Hotfix 14건 (5그룹 A-E) + TestFlight v2.4.1+31** | ✅ |
| 21 | 홈 화면 UX (노티센터/격려/알림) | 대기 |
| **22** | **Badge System (C-1~C-4 + Badge-0)** | 진행 중 |

### 2026-02-06 롤백 기록

```
원인: Sprint 18-R HF + Sprint 19에서 Claude Code가 CLAUDE.md 규칙 전면 무시
  - 하드코딩 한글 20건+, Icons. 직접 사용 25건+
  - 레거시 코드 미삭제, 작업지시서와 다른 구현 (2x2 → 1x3)
대응: a2f1ca2로 전체 롤백, 품질 게이트 시스템 도입
```

### 2026-02-08 차트 사고 기록

```
원인: Column/Row/Expanded + CustomPaint 4단 중첩에서 intrinsic height 계산 실패
  - 7회 이상 부분 수정 시도 전부 실패 (12시간 소요)
근본 원인: 구조가 원인인데 파라미터만 조정
해결: Column/Row 전부 삭제 → 단일 CustomPaint(_WeeklyGridPainter)로 교체
교훈: 3회 실패 룰, 디버그 시각화 먼저, 지시 코드 변형 금지
```

---

## Quality Gate

```
□ Pre-commit hook 통과 (하드코딩 한글, print문, analyze)
□ Phase별 스크린샷 검증 완료
□ Phase 완료 시 즉시 커밋 (커밋 타이밍 규칙)
□ flutter analyze 에러 0개
□ SUS 80+, TTC < 3초
□ "둘 다" 버튼/비교 표현 0개
□ WHO/AAP 출처 명시, 면책조항
□ SGA 자동 감지 정확
□ MCP-V1~V4 통과 (Supabase 변경 시)
□ 이모지 0개, 하드코딩 한글 0개, Icons. 직접 사용 0개
□ On-Device 울음 분석, 오디오 저장 X
□ 레거시 위젯 참조 0개
□ 작업 브랜치에서 작업, main 직접 커밋 금지
□ CustomPaint가 Column 안에 있으면 부모에 고정 높이 확인 (v7.1)
□ Future 반환 함수 호출에 await 있는지 확인 (v7.1)
□ "수정됨" 아닌 "확인됨+스크린샷"으로 보고 (v7.1)
□ 지시된 코드 변형 시 사전 승인 받았는지 확인 (v7.1)
□ 해결 완료된 코드 건드리지 않았는지 확인 (v7.1)
□ full restart로 확인 (hot reload 아님) (v7.2)
```

---

## 문서 체계 (v7.3 강화)

> **사유**: 세션 전환 시 컨텍스트 유실로 같은 실수 반복.
> handoff.md를 세션 종료 시 반드시 업데이트하여 다음 세션이 즉시 작업 가능하게 한다.

| 문서 | 역할 | 변경 빈도 | 필수 업데이트 시점 |
|------|------|-----------|-------------------|
| **RULES.md** | 절대 규칙 | 거의 안 바뀜 | 규칙 추가 시 |
| **CLAUDE.md** | 기술 스펙, 아키텍처, 품질 게이트, 운영 매뉴얼 | 스프린트마다 | Sprint 완료 시 |
| **handoff.md** | 현재 상태, 다음 작업, 세션 간 인수인계 | **매 세션** | **세션 종료 시 필수** |
| **CHANGELOG.md** | 변경 이력 | 매 배포 | TestFlight 업로드 후 |
| **Quality_Gate_System.md** | Pre-commit hook 설치/상세 | 필요 시 | Gate 규칙 변경 시 |
| **Chart_Postmortem.md** | 차트 사고 회고 + Claude Code 교육 | 참고용 | - |
| **work_instruction_template_v2.1.md** | 작업지시서 표준 서두 4블록 (전체 예시 포함) | 거의 안 바뀜 | 프로세스 변경 시 |

### handoff.md 필수 기록 항목 (세션 종료 시)

```
1. 현재 상태: 브랜치, 버전, 마지막 커밋, TestFlight 상태
2. 이번 세션에서 한 것: 구체적 변경 목록
3. 다음 세션에서 할 것: 명확한 다음 작업
4. 주의사항: 이번 세션에서 발견한 이슈/함정
5. 자주 쓴 명령어/값: 반복 참조한 데이터 (CLAUDE.md에 없으면 추가)
```

### 새 데이터 발견 시 문서화 규칙 (v7.3)

```
1. 세션 중 반복 참조한 값 → CLAUDE.md "프로젝트 상수" 테이블에 추가
2. 세션 중 새로 알게 된 명령어 → CLAUDE.md "운영 매뉴얼"에 추가
3. 세션 중 발생한 사고 → CLAUDE.md 해당 섹션에 교훈 추가
4. "다음에도 필요할 것 같다" → 무조건 문서화 (기억에 의존 금지)
```

---

## Learned Corrections (v7.4 신설)

> 실제 사고/실수에서 추출한 교훈. 새 실수 발생 시 LC-N으로 계속 누적.

### LC-1: 코드 존재 =/= 코드 작동 (2026-02-06)

**사건**: Sprint 18에서 28개 파일 동시 변경 후 "수정 완료" 보고했으나, 실기기에서 빌드 실패.
**원인**: 코드 리뷰만으로 "작동한다"고 판단. 실행 확인 없이 보고.
**규칙**: 모든 수정은 **실행 기반 검증** 필수. "읽었다" =/= "확인했다".
**적용**: Confidence Score 8/10 이상만 완료 보고 가능.

### LC-2: 롤백 안전선 부재 (2026-02-06)

**사건**: Sprint 18 롤백 시 돌아갈 기준점이 불명확하여 복구에 시간 소요.
**원인**: main 브랜치에 직접 커밋 + 안전 커밋 미지정.
**규칙**: main 보호, feature branch에서만 작업, 안전 기준선 커밋 항상 명시.
**적용**: handoff.md에 안전 기준선 섹션 필수.

### LC-3: 차트 오판 — 코드 문제 vs 데이터 문제 (2026-02-07)

**사건**: 주간 차트에서 수면 데이터가 과다 표시. 코드 버그로 판단하고 코드를 수정했으나, 실제 원인은 UTC<->Local 변환 누락.
**원인**: 증상 → 코드 수정으로 바로 진행. 데이터 레이어 검증 생략.
**규칙**: 차트/통계 이상 시 **데이터 먼저 확인** (MCP 쿼리) → 코드 수정은 그 다음.
**적용**: Supabase 검증 게이트 트리거 조건에 "차트/통계 데이터 이상 의심" 포함.

### LC-4: Supabase 쿼리 미대조 (2026-02-08)

**사건**: 코드에서 Supabase 쿼리 작성 시 실제 DB 스키마와 컬럼명이 다른 채로 커밋.
**원인**: 코드에 적힌 컬럼명을 그대로 신뢰. DB에서 실제 확인 안 함.
**규칙**: Supabase 쿼리 작성/수정 시 반드시 **MCP로 실제 스키마 대조**.
**적용**: 작업지시서에 Supabase 게이트 블록 필수 삽입.

### LC-5: UTC 누락 — 시간 관련 버그의 근본 원인 (2026-02-07)

**사건**: 활동 기록의 시간이 9시간 차이로 표시됨 (KST<->UTC).
**원인**: Supabase는 UTC 저장, Flutter UI는 Local 시간 표시. 변환 로직이 일부 경로에서 누락.
**규칙**: 시간 관련 코드 수정 시 **항상 UTC<->Local 변환 확인**.
**적용**: 차트, 통계, 기록 목록 등 시간 표시하는 모든 위젯에서 `.toLocal()` 확인.
