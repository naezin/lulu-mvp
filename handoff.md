# LULU MVP-F Handoff

**Version**: 5.4
**Updated**: 2026-02-02
**Sprint**: 10 (완료) + HOTFIX

## 현재 상태
- **Phase**: Phase 2 울음 분석 홈 화면 통합 완료 + Empty State HOTFIX
- **빌드**: iOS/Android 정상 (`flutter analyze` 에러 0개)
- **온보딩**: 완료 (6단계)
- **Phase 2**: 울음 분석 홈 화면 통합 완료
- **Branch**: `feature/cry-analysis-ui`

## 최근 작업: HOTFIX - Empty State UX 개선

### 2026-02-02: Empty State 전환 조건 수정

**문제**:
- 수유/기저귀 기록해도 "첫 기록을 시작해보세요" 메시지 계속 표시
- Empty State에서 불필요한 LastActivityRow (- - -) 표시

**해결**:
| 항목 | 변경 전 | 변경 후 |
|------|---------|---------|
| 전환 조건 | 수면 기록 있을 때만 Normal State | 수유/수면/기저귀 중 하나라도 있으면 Normal State |
| Empty State | LastActivityRow 포함 (- - -) | LastActivityRow 제거 |
| SweetSpotCard | 수면 없으면 Empty State | 수면 없으면 "수면을 기록하면 예측이 시작돼요" 안내 |

**수정 파일**:
```
lib/features/home/screens/home_screen.dart
├── _buildEmptyActivitiesState(): LastActivityRow 제거
├── _buildNormalContent(): hasOtherActivitiesOnly 조건 추가
└── SweetSpotCard isEmpty 조건 수정

lib/shared/widgets/sweet_spot_card.dart
├── hasOtherActivitiesOnly prop 추가
└── _buildNoSleepGuideCard() 메서드 추가

lib/l10n/app_ko.arb, app_en.arb
├── sweetSpotNoSleepTitle
├── sweetSpotNoSleepHint
└── sweetSpotRecordSleepButton
```

**UI 변화**:
```
Empty State (기록 없음):
┌─────────────────────────────────────────┐
│ 🎺 민정의 첫 기록을 시작해보세요        │
│    [수유] [수면] [기저귀]               │
├─────────────────────────────────────────┤
│ 🎤 울음 분석                       NEW │
└─────────────────────────────────────────┘
• LastActivityRow (- - -) 제거됨 ✅

Normal State (수유만 기록):
┌─────────────────────────────────────────┐
│ 🌙 -    🍼 2시간 전    👶 -            │
├─────────────────────────────────────────┤
│ 😴 수면을 기록하면 예측이 시작돼요     │
│    [수면 기록하기]                      │
├─────────────────────────────────────────┤
│ 🎤 울음 분석                       NEW │
└─────────────────────────────────────────┘
• 수유 기록 → 바로 Normal State ✅
• SweetSpot 안내 메시지 ✅

Normal State (수면까지 기록):
┌─────────────────────────────────────────┐
│ 🌙 1시간 전  🍼 2시간 전  👶 30분 전   │
├─────────────────────────────────────────┤
│ 😴 다음 낮잠까지 약 30분               │
│    지금 재우면 좋은 타이밍이에요        │
├─────────────────────────────────────────┤
│ 🎤 울음 분석                       NEW │
└─────────────────────────────────────────┘
• 기존대로 예측 표시 ✅
```

## Sprint 10 완료 내역

| Part | 작업 | 상태 |
|------|------|------|
| Part A | TFLite 모델 생성 (442KB, 83.6%) | ✅ |
| Part B | record 패키지 실제 녹음 | ✅ |
| Part C | iOS/Android 권한 설정 | ✅ |
| Part D | QA 코드 리뷰 통과 | ✅ |
| Part E | 홈 화면 통합 설계 (SUS 85.5, TTC 1.9초) | ✅ |
| **Part F** | **홈 화면 CryAnalysisCard 통합** | **✅** |

## Sprint 7-8 완료 내역

| Part | 작업 | 상태 |
|------|------|------|
| Day 1-2 | OngoingSleepCard → SweetSpotCard 통합 | ✅ |
| Day 2 | QuickActionGrid → FAB 대체 | ✅ |
| Day 2 | LastActivityRow 신규 추가 | ✅ |
| Part A | CSV 내보내기 기능 | ✅ |
| Part B | 설정 화면 구현 | ✅ |
| Part C | i18n 다국어 확장 | ✅ |
| Part E | HomeProvider 캐싱 최적화 | ✅ |
| Part F | 이모지 → Material Icons 교체 | ✅ |

## Phase 2 울음 분석 구현 현황

### 완료된 파일 (12개 + 홈 통합)

```
lib/features/cry_analysis/
├── models/
│   ├── cry_type.dart                 ✅ Dunstan 5타입 + Unknown
│   ├── cry_analysis_result.dart      ✅ 확률 분포, 신뢰도
│   └── cry_analysis_record.dart      ✅ 히스토리 + 통계
├── services/
│   ├── audio_input_service.dart      ✅ 실제 마이크 녹음
│   ├── audio_preprocessor.dart       ✅ Mel Spectrogram
│   ├── cry_classifier.dart           ✅ 실제 TFLite 추론
│   └── preterm_adjustment.dart       ✅ 조산아 보정
├── providers/
│   └── cry_analysis_provider.dart    ✅ 상태 관리, Freemium
├── screens/
│   └── cry_analysis_screen.dart      ✅ 메인 UI
└── widgets/
    ├── cry_analysis_button.dart      ✅ 상태별 버튼
    ├── cry_result_card.dart          ✅ 결과 카드
    └── probability_bar.dart          ✅ 확률 바

lib/features/home/widgets/
└── cry_analysis_card.dart            ✅ 홈 화면 진입점 카드

lib/core/config/
└── feature_flags.dart                ✅ enableCryAnalysis = true

lib/core/design_system/
├── lulu_colors.dart                  ✅ LuluCryAnalysisColors, LuluBadgeColors
└── lulu_icons.dart                   ✅ microphone, soundWave 등

assets/models/
└── cry_classifier.tflite             ✅ 442KB, 83.6% 정확도
```

### 홈 화면 구조

```
1. BabyTabBar              ← 최상단 고정
2. LastActivityRow         ← 수면/수유/기저귀 경과시간 (Normal State만)
3. SweetSpotCard           ← 수면 예측 / 수면 안내
4. CryAnalysisCard         ← 🆕 울음 분석 진입점 (NEW 배지)
5. FAB                     ← 하단 플로팅
```

## Feature Flag 사용법

```dart
// lib/core/config/feature_flags.dart
class FeatureFlags {
  static const bool enableCryAnalysis = true;  // false로 변경하면 숨김
}

// HomeScreen에서 사용
if (FeatureFlags.enableCryAnalysis) ...[
  CryAnalysisCard(onTap: () => _navigateToCryAnalysis(context)),
],
```

## Git 브랜치 전략

```
main ─────────────────────────────────────────────
      \
       feature/cry-analysis-ui ──────────────────  ← 현재 브랜치
```

- `main`: 안정 버전 (Feature Flag로 울음 기능 숨김 가능)
- `feature/cry-analysis-ui`: 울음 분석 UI 개발용

## 알려진 이슈
없음

## TODO

### 즉시 (Sprint 11)
- [ ] 히스토리 화면 구현 (CryHistoryScreen)
- [ ] 설정 화면 연동 (울음 분석 설정)
- [ ] 접근성 추가 (VoiceOver/TalkBack)
- [ ] 실제 아기 울음 테스트

### 출시 전 필수
- [ ] QA 테스트 (TC-01 ~ TC-08)
- [ ] TestFlight 배포
- [ ] 베타 테스터 피드백 수집

## ⚠️ 릴리즈 전 필수 (Security)

| 항목 | 상태 | 조치 |
|------|------|------|
| 하드코딩 API 키 | ✅ 통과 | `.env` 사용, git 추적 안 됨 |
| 민감한 데이터 로깅 | ✅ 통과 | 비밀번호/토큰/이메일 로깅 없음 |
| **Supabase RLS** | ⚠️ **필수** | MVP용 "Allow all" 정책 → 원래 정책 복구 |

### RLS 복구 방법
```sql
-- 1. MVP 정책 삭제
DROP POLICY "Allow all for MVP" ON families;
DROP POLICY "Allow all for MVP" ON babies;
DROP POLICY "Allow all for MVP" ON activities;

-- 2. 001_initial_schema.sql의 원래 RLS 정책 다시 적용
```

## 주요 파일 참조

### HOTFIX 관련 파일
- `lib/features/home/screens/home_screen.dart` - 전환 조건, Empty State 수정
- `lib/shared/widgets/sweet_spot_card.dart` - 수면 안내 카드 추가
- `lib/l10n/app_ko.arb`, `lib/l10n/app_en.arb` - 다국어 문자열

### Phase 2 핵심 파일
- `lib/features/cry_analysis/` - 울음 분석 전체 모듈
- `lib/features/home/widgets/cry_analysis_card.dart` - 홈 화면 진입점
- `lib/core/config/feature_flags.dart` - Feature Flag
- `assets/models/cry_classifier.tflite` - TFLite 모델

### v5.1-5.2 핵심 파일
- `lib/shared/widgets/sweet_spot_card.dart` - 통합 카드
- `lib/shared/widgets/last_activity_row.dart` - 경과 시간 표시
- `lib/features/home/screens/home_screen.dart` - 홈 화면

---

**Sprint 10 + HOTFIX 완료** ✅

**Next Session**: 히스토리 화면 + 실제 울음 테스트 + TestFlight 배포
