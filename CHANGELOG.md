# CHANGELOG

## [2.2.3+11] - 2026-02-04

### Added
- **기록 히스토리 + 주간 패턴 차트** (작업지시서 v1.1)
  - `DateNavigator`: 날짜 좌우 탐색 위젯 (< 3초)
  - `MiniTimeBar`: 24시간 타임라인 시각화
  - `DailySummaryBanner`: 일일 요약 배너
  - `ActivityListItem`: 스와이프 삭제/편집 (flutter_slidable)
  - `EditActivitySheet`: 활동 편집 바텀시트
  - `WeeklyPatternChart`: 7일×48슬롯 히트맵
  - `PatternDataProvider`: 패턴 데이터 캐싱
  - `UndoDeleteMixin`: 5초 실행취소 기능

### Changed
- **UX 개선**
  - Haptic feedback 추가 (`selectionClick`, `mediumImpact`, `heavyImpact`)
  - `WeeklyPatternChartSkeleton`: Shimmer 로딩 스켈레톤
  - `TogetherViewButton`: 다태아 패턴 함께보기
  - Week Navigation: 이전/다음 주 탐색

### Deployed
- **TestFlight**: v2.2.3+11 업로드 완료 (2026-02-04 22:45)

---

## [2.2.2+11] - 2026-02-04

### Fixed
- **RLS 42501 에러 수정** (activities INSERT 실패)
  - 원인: Apple Sign-In 앱 재설치 시 새 uid 생성 → family_members에 없음 → RLS 거부
  - 수정: `main.dart` 로컬 복원 시 family_members upsert 추가
  - 상세 회고: `docs/rls-prevention-claude-code-additions.md`

### Added
- **RLS 재발 방지 가이드** 문서화
  - `CLAUDE.md`: RLS 작업 체크리스트 추가
  - `handoff.md`: 재발 방지 체크리스트 추가
  - `docs/rls-prevention-claude-code-additions.md`: Claude Code 특화 가이드

### Lessons Learned
```
⚠️ 11회 반복된 동일 실수의 교훈:
- "데이터 존재" ≠ "현재 사용자의 데이터 존재"
- RLS는 "데이터"가 아닌 "권한"을 검증 (auth.uid() 기준)
- families INSERT 후 반드시 family_members INSERT 필요
- Apple Sign-In: 앱 재설치 시 새 uid 생성됨 (Google/Email은 유지)
```

## [2.2.2+10] - 2026-02-04

### Added
- **Family Sharing v3.2**: 완전 구현
  - `family_members` 테이블: 가족 멤버 관계 관리
  - `family_invites` 테이블: 초대 코드 시스템
  - RPC 함수: `get_invite_info`, `accept_invite`, `transfer_ownership`, `leave_family`
  - 헬퍼 함수: `is_family_member`, `is_family_owner`, `is_family_member_or_legacy`

### Changed
- **RLS 정책 완전 개편** (보안 강화)
  - `families`: 4개 정책 (select/insert/update/delete)
  - `babies`: 4개 정책 (select/insert/update/delete)
  - `activities`: 4개 정책 (select/insert/update/delete)
  - 모든 정책이 `is_family_member_or_legacy()` 함수 사용
- `FamilyRepository.createFamily()`: `family_members`에 owner 자동 INSERT 추가

### Removed
- **"Allow all for MVP" 정책 삭제** (보안 위험 제거)
  - `DROP POLICY "Allow all for MVP" ON families`
  - `DROP POLICY "Allow all for MVP" ON babies`
  - `DROP POLICY "Allow all for MVP" ON activities`

### Fixed
- 레거시 사용자 호환: `families.user_id` fallback + 자동 마이그레이션

## [2.2.2+10] - 2026-02-03

### Fixed
- **BUG-DATA-01**: FK 에러 (activities_family_id_fkey) 근본 원인 수정
  - `FamilySyncService`: `family_members` → `families` 테이블 직접 조회
  - `RecordProvider`: `LocalActivityService` → `ActivityRepository` (Supabase 직접 저장)
  - `OngoingSleepProvider`: `LocalActivityService` → `ActivityRepository`
  - `OnboardingDataService`: `family_id` 키 별도 저장 추가 (SharedPreferences 호환성)

### Changed
- 로그인 화면 UI 개선
  - 로고: 온보딩과 동일한 LULU 로고 적용 (그라데이션 + 그림자)
  - 태그라인 "우리 아기 울음의 비밀" 제거
  - Google 버튼 제거 (미구현)
  - 이메일 버튼: `OutlinedButton` → `ElevatedButton.icon`
- 아기 수 선택 화면 아이콘 변경
  - `Icons.child_friendly_rounded` (유모차) → `Icons.child_care_rounded` (아기 얼굴)

## [2.2.1+9] - 2026-02-03

### Added
- Apple Sign In 구현 (Native SDK: `sign_in_with_apple`)
- Email 로그인/회원가입 구현
- `FamilySyncService`: 로컬/Supabase Family 동기화

### Fixed
- Import 시 Family 존재 확인 로직 추가

## [2.2.0+8] - 2026-02-03

### Added
- Apple + Email 인증 시스템
- `ProfileModel`, `ProfileService`
- `AuthProvider`, `LoginScreen`, `EmailLoginScreen`
- Supabase `profiles` 테이블 + RLS + Trigger
- `ios/Runner/Runner.entitlements` (Sign in with Apple)

## [2.1.0+7] - 2026-02-03

### Added
- Phase 2 울음 분석 모듈 완성
- TFLite 모델 (442KB, 83.6% 정확도)
- Dunstan 5타입 분류 (Neh, Owh, Heh, Eairh, Eh)
- 조산아 보정 로직
- Feature Flag 시스템

### Fixed
- Empty State UX 개선
- 온보딩 Supabase 저장 로직 추가

## [0.1.0-dev] - 2026-01-30

### Fixed
- iOS: Navigator context 오류 수정 (`_OnboardingWrapper` 래퍼 추가)
- Android: 한글 IME 조합 문제 해결 (Impeller 비활성화)

### Added
- 온보딩 플로우 6단계 완료
- Supabase 연동
- OpenAI 연동
- 성장 차트 (Fenton/WHO 데이터)

## [0.0.1] - 2026-01-29

### Added
- 프로젝트 초기 설정
- Flutter 3.38.7 기반 구조
