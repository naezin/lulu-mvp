# LULU MVP-F Handoff

**Version**: 9.0
**Updated**: 2026-02-10
**Sprint**: 20 Hotfix (완료)

---

## 현재 상태

| 항목 | 값 |
|------|-----|
| Branch | `sprint-20-hotfix` |
| App Version | `2.4.1+31` |
| Build | iOS 정상 (`flutter analyze` 에러 0개) |
| TestFlight | 배포 완료 (2026-02-10) |
| Delivery UUID | `ca669fc8-6dfa-4188-873e-68ecd908cb97` |
| Base Commit (Sprint 19) | `a2f1ca2` |
| Latest Commit | `3947e82` (CLAUDE.md TestFlight credentials) |

### Sprint 20 Hotfix 커밋 이력

| 순서 | Hash | 내용 |
|------|------|------|
| 1 | `42a50fe` | Group A |
| 2 | `687c4de` | Group B |
| 3 | `7955e8e` | Group C |
| 4 | `377b6e9` | Group D |
| 5 | `a72223b` | Group E |
| 6 | `1cc4ddb` | Version bump v2.4.1+31 |
| 7 | `3947e82` | CLAUDE.md TestFlight credentials |

---

## 2026-02-10 세션 기록

### 이번 세션에서 한 것

1. **Sprint 20 Hotfix Group C/D/E 커밋** (A/B는 이전 세션에서 완료)
   - Group C: `statistics_data_provider.dart` 이모지 수정
   - Group D: 4개 파일 이모지 + 한글 하드코딩 수정
     - `invite_service.dart`, `home_screen.dart`, `ongoing_sleep_provider.dart`, `record_provider.dart`
   - Group E: 정상 커밋

2. **버전 범프**: `2.4.0+30` -> `2.4.1+31`

3. **IPA 빌드 + TestFlight 업로드 성공**

4. **CLAUDE.md v7.3 업데이트**
   - "프로젝트 상수" 테이블 추가 (반복 참조 값 집중)
   - "운영 매뉴얼" 섹션 추가 (복붙용 명령어)
   - Sprint 이력 업데이트
   - 문서 체계 강화 (handoff.md 필수 업데이트 규칙)

### 이번 세션에서 발생한 이슈

1. **TestFlight Issuer ID 오타 사고** (재발)
   - `69a6de96` (틀림) vs `69a6de8c` (맞음)
   - 원인: CLAUDE.md에 인증 정보가 없어서 기억에 의존
   - 대응: CLAUDE.md에 영구 기록 완료

2. **Pre-commit Gate 이모지 차단** (Group C, D)
   - debugPrint 안의 이모지 (`[OK]`/`[ERR]`/`[WARN]`/`[INFO]` 태그로 교체)
   - 한글 하드코딩 (`home_screen.dart` - 영문 debugPrint로 교체)

---

## 다음 세션에서 할 것

### 즉시 필요

- [ ] `sprint-20-hotfix` -> `main` 머지 (사용자 승인 후)
- [ ] 베타 테스터 피드백 수집

### 대기 중

- [ ] Sprint 21: 홈 화면 UX (노티센터/격려/알림)
- [ ] Family Sharing 기능 테스트 (초대 코드 생성/수락)
- [ ] 기록 히스토리/패턴 차트 사용성 테스트

### 출시 전 필수

- [ ] QA 테스트 완료
- [ ] 앱스토어 심사 제출

---

## 주의사항 (다음 세션 참고)

1. **TestFlight 업로드 시**: CLAUDE.md "운영 매뉴얼" 섹션의 명령어를 그대로 복붙. Issuer ID를 절대 기억으로 입력하지 말 것.

2. **커밋 시 Pre-commit hook**: Gate 1(한글), Gate 2(이모지)에 주의. debugPrint 안의 한글/이모지도 차단됨.

3. **브랜치**: 현재 `sprint-20-hotfix`. `main`에 직접 커밋 금지.

4. **해결 완료 코드 (건드리지 말 것)**:
   - `weekly_chart_full.dart`의 `_WeeklyGridPainter` 구조
   - `_navigateWeek`의 async/await 구조
   - `goToPreviousWeek`/`goToNextWeek`의 await
   - 1행 1줄 덮어그리기 렌더링 방식

---

## DB 스키마 (Sprint 17 이후 변경 없음)

### 테이블

- **profiles** - 사용자 프로필
- **families** - 가족 정보 (user_id, created_by)
- **babies** - 아기 정보
- **activities** - 활동 기록
- **family_members** - 가족 멤버 관계 (UNIQUE: family_id + user_id)
- **family_invites** - 초대 코드 (6자리, 7일 유효)

### RLS 정책 (12개)

activities(4) + babies(4) + families(4) -- 모두 `is_family_member_or_legacy()` 기반

### 함수 (7개)

`is_family_member`, `is_family_owner`, `is_family_member_or_legacy`, `get_invite_info`, `accept_invite`, `transfer_ownership`, `leave_family`

---

## 데이터 흐름 (v7.1 이후 변경 없음)

```
앱 시작 -> 로그인 체크 -> OnboardingWrapper
  -> family_members에서 family_id 확인
  -> 있으면 HomeScreen / 없으면 OnboardingScreen
기록 저장 -> RecordProvider -> ActivityRepository -> Supabase (RLS 검증)
```

---

*"handoff.md = 세션 간 인수인계 문서. 매 세션 종료 시 반드시 업데이트."*
