# LULU MVP-F Handoff

**Version**: 5.2
**Updated**: 2026-01-31
**Sprint**: 8 (거의 완료)

## 현재 상태
- **Phase**: MVP 개발 마무리 (Sprint 8 거의 완료)
- **빌드**: iOS/Android 정상 (`flutter analyze` 에러 0개)
- **온보딩**: 완료 (6단계)
- **v5.1 Code Update**: 완료
- **v5.2 Update**: 빈 상태 카드 통합, 문서 동기화

## Sprint 7 완료 내역

| Day | 작업 | 상태 |
|-----|------|------|
| Day 1 | 버그 수정 (BUG-003, BUG-004) | ✅ |
| Day 2 | OngoingSleepCard → SweetSpotCard 통합 | ✅ |
| Day 2 | QuickActionGrid → FAB 대체 | ✅ |
| Day 2 | LastActivityRow 신규 추가 | ✅ |
| Day 2 | 빈 상태 2종 카드 → 1종 통합 (CARD-01~04) | ✅ |
| Day 3+ | Play/Health UX 개선 | ✅ |

## Sprint 8 완료 내역

| Part | 작업 | 상태 |
|------|------|------|
| Part A | CSV 내보내기 기능 | ✅ |
| Part B | 설정 화면 구현 | ✅ |
| Part C | i18n 다국어 확장 | ✅ |
| Part E | HomeProvider 캐싱 최적화 | ✅ |
| Part F | 이모지 → Material Icons 교체 | ✅ |

## 미구현 항목 체크리스트 (종합)

| 카테고리 | ID | 항목 | 상태 |
|----------|-----|------|------|
| Home v2.0 | UI-01 | LastActivityRow (수면/수유/기저귀) | ✅ |
| Home v2.0 | UI-02 | FAB → ExpandableFab | ✅ |
| Home v2.0 | UI-03 | OngoingSleepCard → SweetSpotCard | ✅ |
| Home v2.0 | UI-04 | 빈 상태 카드 통합 | ✅ |
| SGA 지원 | SGA-01 | SGA 감지 + 뱃지 표시 | ✅ |
| 내보내기 | MA-01 | CSV 내보내기 | ✅ |
| 아기관리 | BABY-01 | 아기 추가/삭제 | ✅ |
| UI 통일 | EMOJI-01 | 이모지 → Material Icons | ✅ |

## 최근 작업

### 2026-01-31: v5.2 업데이트
- 빈 상태 2종 카드 → SweetSpotCard 1종으로 통합
- SweetSpotCard에 onFeedingTap, onSleepTap, onDiaperTap 콜백 추가
- home_screen.dart의 _buildEmptyActivitiesState() 단순화
- i18n 키 추가: sweetSpotEmptyTitleWithName, sweetSpotEmptyTitleDefault, sweetSpotEmptyHint
- 문서와 구현 상태 동기화

### 2026-01-31: Sprint 7 Day 2 커밋
- OngoingSleepCard → SweetSpotCard 통합
- QuickActionGrid 삭제 (FAB로 대체)
- LastActivityRow 신규 추가 (수면/수유/기저귀 경과 시간)
- 실시간 경과 시간 Timer 구현
- Growth 화면 UI 개선
- Settings Provider 추가
- Timeline 버그 수정 (filteredTodayActivities)

### 2026-01-30: Sprint 7/8 작업
- Sprint 7 완료
- Sprint 8 Part A-C, E-F 완료
- 이모지 → Material Icons 전환
- HomeProvider 캐싱 최적화

## v5.1 주요 변경사항

### 삭제된 파일
- `lib/shared/widgets/quick_action_grid.dart` → FAB로 대체
- `lib/features/home/widgets/ongoing_sleep_card.dart` → SweetSpotCard 통합
- `test/shared/widgets/quick_action_grid_test.dart`

### 신규 파일
- `lib/shared/widgets/sweet_spot_card.dart` - SweetSpotCard (통합 위젯)
- `lib/shared/widgets/last_activity_row.dart` - 마지막 활동 Row
- `lib/features/settings/providers/settings_provider.dart` - 설정 Provider

### 수정된 파일
- `lib/features/home/screens/home_screen.dart` - StatefulWidget으로 변경
- `lib/features/home/providers/home_provider.dart` - 캐싱 최적화

## 알려진 이슈
없음

## TODO (Sprint 8 남은 작업)
- [ ] PA-01: 온보딩→홈 즉시 반영 검증
- [ ] CS-01: 마이크로카피 "다음" 통일 검증
- [ ] QA 테스트
- [ ] 출시 준비

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
-- (Users can view/insert/update/delete own families/babies/activities)
```

참고 파일: `supabase/migrations/002_disable_rls_for_mvp.sql`

## Phase 2 TODO (Sprint 8 이후)
- [ ] Sweet Spot 알고리즘 고도화
- [ ] Fenton/WHO 차트 전환
- [ ] Apple Watch 위젯
- [ ] AI 울음 분석

## 주요 파일 참조

### v5.1 핵심 파일
- `lib/shared/widgets/sweet_spot_card.dart` - 통합 카드 (수면 중 + Sweet Spot)
- `lib/shared/widgets/last_activity_row.dart` - 경과 시간 표시
- `lib/features/home/screens/home_screen.dart` - 홈 화면

### 테스트 파일
- `test/features/record/record_provider_test.dart` - RecordProvider 단위 테스트
- `test/shared/widgets/baby_tab_bar_test.dart` - BabyTabBar 위젯 테스트
- `test/shared/widgets/quick_record_button_test.dart` - QuickRecordButton 위젯 테스트

## v5.2 변경 파일

### 수정된 파일
- `lib/shared/widgets/sweet_spot_card.dart` - 빈 상태 통합, 3종 quick action 추가
- `lib/features/home/screens/home_screen.dart` - _buildEmptyActivitiesState 단순화
- `lib/l10n/app_ko.arb` - i18n 키 추가
- `lib/l10n/app_en.arb` - i18n 키 추가

### 구현 완료 확인된 파일
- `lib/core/utils/sga_calculator.dart` - SGA 감지 로직
- `lib/features/home/widgets/baby_status_badge.dart` - SGA 뱃지 표시
- `lib/core/services/export_service.dart` - CSV 내보내기
- `lib/features/settings/widgets/add_baby_dialog.dart` - 아기 추가
- `lib/features/settings/widgets/delete_baby_dialog.dart` - 아기 삭제
- `lib/shared/widgets/expandable_fab.dart` - Material Icons 적용
- `lib/features/growth/widgets/*.dart` - Material Icons 적용

---

**Sprint 8 거의 완료** ✅

**Next Session**: QA 테스트 + 출시 준비
