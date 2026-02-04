# LULU MVP-F Handoff

**Version**: 8.0
**Updated**: 2026-02-04
**Sprint**: 17 (기록 히스토리 + 주간 패턴 차트)

## 현재 상태
- **Phase**: Phase 2 완료 + 기록 히스토리 v1.1 완료
- **App Version**: 2.2.3+11
- **빌드**: iOS 정상 (`flutter analyze` 에러 0개)
- **Branch**: `main`
- **TestFlight**: ✅ **배포 완료** (2026-02-04 22:45)
- **Supabase**: Family Sharing v3.2 + RLS 보안 완료

## TestFlight 배포 현황

| 항목 | 상태 |
|------|------|
| App Version | **2.2.3+11** |
| Bundle ID | com.lululabs.lulu |
| 앱스토어 이름 | 루루 |
| TestFlight | **✅ 업로드 완료** |
| Family Sharing DB | **완전 완료** |
| RLS 정책 | **12개 (보안 완료)** |
| 코드 검증 | **완전 완료** |

---

## 2026-02-04 기록 히스토리 + 주간 패턴 차트 (Sprint 17)

### 구현 완료 (작업지시서 v1.1)

| 위젯 | 파일 | 설명 |
|------|------|------|
| **DateNavigator** | `date_navigator.dart` | 날짜 좌우 탐색 (< 3초) |
| **MiniTimeBar** | `mini_time_bar.dart` | 24시간 타임라인 시각화 |
| **DailySummaryBanner** | `daily_summary_banner.dart` | 일일 요약 배너 |
| **ActivityListItem** | `activity_list_item.dart` | 스와이프 삭제/편집 |
| **EditActivitySheet** | `edit_activity_sheet.dart` | 활동 편집 바텀시트 |
| **WeeklyPatternChart** | `weekly_pattern_chart.dart` | 7일×48슬롯 히트맵 |
| **PatternDataProvider** | `pattern_data_provider.dart` | 패턴 데이터 캐싱 |
| **UndoDeleteMixin** | `undo_delete_mixin.dart` | 5초 실행취소 |

### UX 개선

- **Haptic Feedback**: `selectionClick`, `mediumImpact`, `heavyImpact`
- **WeeklyPatternChartSkeleton**: Shimmer 로딩 스켈레톤
- **TogetherView**: 다태아 패턴 함께보기
- **Week Navigation**: 이전/다음 주 탐색
- **Empty State**: 데이터 3일 미만 시 안내

### 새 파일 (9개)

```
lib/features/timeline/
├── models/
│   └── daily_pattern.dart
├── providers/
│   └── pattern_data_provider.dart
└── widgets/
    ├── activity_list_item.dart
    ├── daily_summary_banner.dart
    ├── date_navigator.dart
    ├── edit_activity_sheet.dart
    ├── mini_time_bar.dart
    ├── weekly_pattern_chart.dart
    └── widgets.dart (barrel)

lib/shared/widgets/
└── undo_delete_mixin.dart
```

---

## 2026-02-04 RLS 42501 버그 수정 (Session 18 - 최종)

### 🔴 교훈: 11회 반복된 같은 실수

**근본 원인**: "데이터 존재" ≠ "현재 사용자의 데이터 존재"
- RLS는 "데이터"가 아닌 "권한"을 검증 (auth.uid() 기준)
- Apple Sign-In 재설치 시 새 uid 생성 → family_members에 없음 → RLS 실패

### 수정 내용 ✅

1. **main.dart** (로컬 복원 시 family_members upsert 추가)
   ```dart
   // ✅ RLS FIX: 로컬 복원 시에도 family_members에 현재 사용자 추가
   final currentUserId = Supabase.instance.client.auth.currentUser?.id;
   if (currentUserId != null) {
     await Supabase.instance.client.from('family_members').upsert({
       'family_id': family.id,
       'user_id': currentUserId,
       'role': 'owner',
     });
   }
   ```

2. **SQL 직접 수정** (MCP 통해 실행)
   ```sql
   INSERT INTO family_members (family_id, user_id, role)
   VALUES ('<family_id>', '<new_user_id>', 'owner');
   ```

### 재발 방지 필수 검증 쿼리

```sql
-- auth.users ↔ family_members 매칭 확인 (모든 user가 있어야 함)
SELECT au.id, au.email, fm.family_id, fm.role,
  CASE WHEN fm.user_id IS NULL THEN '❌ NOT IN family_members' ELSE '✅ OK' END
FROM auth.users au
LEFT JOIN family_members fm ON fm.user_id = au.id;

-- is_family_member_or_legacy 테스트
SELECT is_family_member_or_legacy('<family_id>');
```

### 상세 가이드 문서

- `docs/rls-prevention-claude-code-additions.md` - Claude Code 특화 재발 방지 가이드

### 🗄️ Supabase Specialist 에이전트 (신규)

RLS 42501 에러가 11회 반복된 교훈으로 전담 에이전트 추가:

```
🎯 미션: "RLS는 논리가 아닌 실행으로 검증한다"

📋 핵심 책임:
• RLS 정책 설계 및 검증
• MCP 검증 쿼리 세트 실행 (MCP-V1~V4)
• family_members 동기화 로직
• Apple Sign-In 특이사항 대응
• Edge Case 테스트 (다기기 로그인 등)

✅ Quality Gate:
□ MCP-V1~V4 모두 통과
□ E2E 테스트 증거 첨부
□ 스크린샷 없이 "완료" 선언 금지

🔗 협업: Security Engineer, Flutter Developer, QA Engineer
```

---

## 2026-02-04 RLS 보안 정리 완료 (Session 17 Final)

### "Allow all for MVP" 정책 삭제 ✅

**삭제된 정책** (보안 위험 제거):
```sql
DROP POLICY "Allow all for MVP" ON families;  -- 삭제됨
DROP POLICY "Allow all for MVP" ON babies;    -- 삭제됨
DROP POLICY "Allow all for MVP" ON activities; -- 삭제됨
```

### 최종 RLS 정책 (12개) ✅

| 테이블 | 정책명 | 설명 |
|--------|--------|------|
| **activities** | activity_delete | 가족 멤버만 삭제 |
| **activities** | activity_insert | 가족 멤버만 추가 |
| **activities** | activity_select | 가족 멤버만 조회 |
| **activities** | activity_update | 가족 멤버만 수정 |
| **babies** | baby_delete | 가족 멤버만 삭제 |
| **babies** | baby_insert | 가족 멤버만 추가 |
| **babies** | baby_select | 가족 멤버만 조회 |
| **babies** | baby_update | 가족 멤버만 수정 |
| **families** | family_delete | 가족 멤버만 삭제 |
| **families** | family_insert | 인증된 사용자만 |
| **families** | family_select | 가족 멤버만 조회 |
| **families** | family_update | 가족 멤버만 수정 |

**RLS 검증 함수**: `is_family_member_or_legacy(family_id)` - 레거시 호환 지원

---

## DB 스키마 (최종)

### 기존 테이블
- **profiles** - 사용자 프로필
- **families** - 가족 정보 (user_id, created_by)
- **babies** - 아기 정보
- **activities** - 활동 기록

### 신규 테이블 (Family Sharing v3.2)
- **family_members** - 가족 멤버 관계
  ```sql
  id UUID PRIMARY KEY
  family_id UUID REFERENCES families(id)
  user_id UUID REFERENCES auth.users(id)
  role TEXT ('owner' | 'member')
  joined_at TIMESTAMPTZ
  UNIQUE (family_id, user_id)  -- upsert용
  ```
- **family_invites** - 초대 코드
  ```sql
  id UUID PRIMARY KEY
  family_id UUID REFERENCES families(id)
  invite_code TEXT UNIQUE
  invited_email TEXT
  created_by UUID REFERENCES auth.users(id)
  expires_at TIMESTAMPTZ
  used_at TIMESTAMPTZ
  used_by UUID
  ```

### 함수 (7개)
1. `is_family_member(p_family_id)` - 멤버 확인 헬퍼
2. `is_family_owner(p_family_id)` - 소유자 확인 헬퍼
3. `is_family_member_or_legacy(p_family_id)` - 레거시 호환 헬퍼
4. `get_invite_info(p_invite_code)` - 초대 정보 조회
5. `accept_invite(p_invite_code, p_baby_mappings)` - 초대 수락
6. `transfer_ownership(p_family_id, p_new_owner_id)` - 소유권 이전
7. `leave_family(p_family_id)` - 가족 나가기

---

## 코드 검증 결과 (6개 항목) ✅

| # | 항목 | 파일 | 상태 |
|---|------|------|------|
| 1 | 온보딩 family_members INSERT | `family_repository.dart` | ✅ |
| 2 | activities family_id 출처 | `record_provider.dart` | ✅ |
| 3 | babies 추가 전 family 확인 | `home_provider.dart` | ✅ |
| 4 | 초대 코드 created_by | `invite_service.dart` | ✅ |
| 5 | 레거시 자동 마이그레이션 | `main.dart` | ✅ |
| 6 | familyId null 체크 | `record_provider.dart` | ✅ |

---

## 데이터 흐름 (최종 v7.1)

```
┌─────────────────────────────────────────────────────────────────┐
│                      앱 시작 플로우 (v7.1)                        │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  1. 로그인 체크                                                 │
│     ├── 미로그인 → LoginScreen                                  │
│     └── 로그인됨 → OnboardingWrapper                            │
│                                                                 │
│  2. OnboardingWrapper                                           │
│     ├── family_members에서 family_id 확인                       │
│     │   ├── 있음 → familyId 획득                                │
│     │   └── 없음 → families.user_id fallback (자동 마이그레이션)│
│     │                                                           │
│     ├── familyId 있음 → _loadExistingFamilyData()              │
│     │   ├── families 테이블 조회 (RLS: family_select)          │
│     │   ├── babies 테이블 조회 (RLS: baby_select)              │
│     │   ├── HomeProvider.setFamily() 호출                       │
│     │   └── HomeScreen 표시                                     │
│     │                                                           │
│     └── familyId 없음 → OnboardingScreen                       │
│                                                                 │
│  3. 온보딩 완료                                                 │
│     FamilyRepository.createFamily()                             │
│          ├── families INSERT (RLS: family_insert)              │
│          └── family_members INSERT (owner)                      │
│                                                                 │
│  4. 기록 저장                                                   │
│     RecordProvider.saveXxx()                                    │
│          ├── familyId null 체크                                 │
│          └── ActivityRepository.createActivity()                │
│               └── activities INSERT (RLS: activity_insert)      │
│                                                                 │
│  5. RLS 검증 (Supabase)                                         │
│     is_family_member_or_legacy(family_id) 호출                  │
│          ├── family_members에 있음 → true                       │
│          └── families.user_id 일치 → true (레거시)              │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

---

## 알려진 이슈

### 해결됨
- [x] FK 에러 (family_id 불일치) - 2026-02-03 해결
- [x] RecordProvider 로컬 저장 버그 - 2026-02-03 해결
- [x] 온보딩 중복 버그 - 2026-02-04 해결
- [x] Timeline 데이터 안 보임 - 2026-02-04 해결
- [x] 체온 입력 시 키보드 가림 - 2026-02-04 해결
- [x] **BUG-008**: 로그인 후 Supabase 체크 안 함 - Hotfix 완료
- [x] **BUG-009**: 아기 추가 시 FK 에러 - Hotfix 완료
- [x] **BUG-010**: Timeline에 데이터 안 보임 - Hotfix 완료
- [x] **family_members 테이블 미존재** - 마이그레이션 완료
- [x] **RLS 정책 미적용** - 12개 정책 적용 완료
- [x] **"Allow all for MVP" 보안 구멍** - 삭제 완료
- [x] **RLS 42501 에러** (activities INSERT 실패) - 2026-02-04 수정
  - 원인: Apple Sign-In 재설치 시 새 uid → family_members에 없음
  - 수정: main.dart 로컬 복원 시 family_members upsert 추가

### 미해결
없음

---

## TODO

### 완료됨 ✅
- [x] Supabase 마이그레이션 SQL 실행
- [x] family_members, family_invites RLS 정책 생성
- [x] RPC 함수 생성 (4개)
- [x] is_family_member_or_legacy 함수 생성
- [x] families/babies/activities RLS 정책 업데이트 (12개)
- [x] **"Allow all for MVP" 정책 삭제** (보안 정리)
- [x] family_repository.dart - family_members INSERT 추가
- [x] 코드 검증 6개 항목 완료
- [x] flutter analyze 통과 확인 (에러 0개)

### 다음 단계
- [x] **TestFlight 배포** (v2.2.3+11) ✅ 완료
- [ ] 베타 테스터 피드백 수집
- [ ] Family Sharing 기능 테스트 (초대 코드 생성/수락)
- [ ] 기록 히스토리/패턴 차트 사용성 테스트

### 출시 전 필수
- [ ] QA 테스트 완료
- [ ] 앱스토어 심사 제출

---

## Supabase 최종 검증 쿼리

```sql
-- 1. RLS 정책 확인 (12개여야 함)
SELECT tablename, policyname FROM pg_policies
WHERE schemaname = 'public'
AND tablename IN ('families', 'babies', 'activities')
ORDER BY tablename, policyname;

-- 2. 함수 확인 (7개)
SELECT routine_name FROM information_schema.routines
WHERE routine_schema = 'public'
AND routine_name IN ('get_invite_info', 'accept_invite', 'transfer_ownership',
                     'leave_family', 'is_family_member', 'is_family_owner',
                     'is_family_member_or_legacy');
```

---

---

## ⚠️ RLS 작업 시 필수 확인 (재발 방지)

```
┌─────────────────────────────────────────────────────────────────┐
│                  RLS 42501 재발 방지 체크리스트                    │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  1. family_members INSERT 누락 없는가?                          │
│     └ families INSERT 후 반드시 family_members에도 INSERT       │
│                                                                 │
│  2. auth.uid()와 family_members 매칭 확인했는가?                │
│     └ MCP 쿼리로 확인 (모든 user가 family_members에 있어야 함)  │
│                                                                 │
│  3. 실제 앱에서 기록 저장 테스트했는가?                         │
│     └ 수유/수면/기저귀 중 최소 1개 저장 성공 확인               │
│                                                                 │
│  🔴 영향받는 파일 (수정 시 반드시 검증)                         │
│     • main.dart (OnboardingWrapper)                             │
│     • family_sync_service.dart                                  │
│     • family_repository.dart                                    │
│     • record_provider.dart                                      │
│                                                                 │
│  📋 상세: docs/rls-prevention-claude-code-additions.md          │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

---

**Sprint 17 완료: 기록 히스토리 + 주간 패턴 차트**

**Status**: ✅ TestFlight 배포 완료 (v2.2.3+11)

---

*"기록 히스토리 v1.1 - 24시간 타임라인 + 7일 패턴 히트맵"*
*"Family Sharing v3.2 - 레거시 호환 + 멀티 테넌트 RLS + 보안 완성"*
*"RLS 검증: 데이터 존재 ≠ 권한 존재 - auth.uid() 기준!"*
