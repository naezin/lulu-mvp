# RLS 이슈 재발 방지 - Claude Code 특화 추가사항

> 사용자의 회고 문서를 보완하는 Claude Code 특화 개선사항입니다.

## 1. MCP 기반 자동 검증 쿼리

### RLS 변경 시 필수 실행 쿼리 세트

```sql
-- [MCP-V1] 현재 auth.uid()와 family_members 매칭 확인
SELECT
  au.id as auth_user_id,
  au.email,
  fm.family_id,
  fm.role,
  CASE WHEN fm.user_id IS NULL THEN '❌ NOT IN family_members' ELSE '✅ OK' END as status
FROM auth.users au
LEFT JOIN family_members fm ON fm.user_id = au.id
ORDER BY au.created_at DESC;

-- [MCP-V2] is_family_member_or_legacy 함수 직접 테스트
SELECT is_family_member_or_legacy('<family_id>') as result;

-- [MCP-V3] RLS 정책이 실제로 작동하는지 시뮬레이션
-- (Supabase Dashboard에서 "Impersonate User"로 테스트)
SELECT * FROM activities WHERE family_id = '<family_id>' LIMIT 1;

-- [MCP-V4] 고아 데이터 확인
SELECT f.id as family_id, f.user_id as owner,
  (SELECT COUNT(*) FROM family_members WHERE family_id = f.id) as member_count
FROM families f
WHERE (SELECT COUNT(*) FROM family_members WHERE family_id = f.id) = 0;
```

### Claude Code 작업 시 자동 체크 트리거

| 트리거 조건 | 자동 실행 쿼리 |
|-------------|----------------|
| RLS 정책 수정 | MCP-V1, MCP-V2 |
| family_members 테이블 변경 | MCP-V1, MCP-V4 |
| 온보딩 코드 수정 | MCP-V1 (테스트 유저로) |
| activities INSERT 코드 수정 | MCP-V2, MCP-V3 |

## 2. 코드 수정 시 필수 검증 패턴

### Pattern A: family_members INSERT 누락 감지

```dart
// ⚠️ 이 패턴을 발견하면 경고:
await supabase.from('families').insert({...});
// ❌ family_members INSERT가 없음!

// ✅ 올바른 패턴:
await supabase.from('families').insert({...});
await supabase.from('family_members').insert({
  'family_id': familyId,
  'user_id': userId,
  'role': 'owner',
});
```

### Pattern B: auth.uid() 변경 가능 시점 확인

```
앱 재설치 시 auth.uid() 변경 여부:
├── Apple Sign-In: ⚠️ 변경됨 (새 uid 생성)
├── Google Sign-In: ✅ 유지됨 (동일 uid)
├── Email/Password: ✅ 유지됨 (동일 uid)
└── Anonymous: ⚠️ 변경됨 (새 uid 생성)

→ Apple Sign-In 사용 시 family_members 재등록 필수
```

## 3. 파일별 RLS 영향 매핑

### 수정 시 RLS 검증 필요 파일

| 파일 | RLS 영향 | 필수 검증 |
|------|---------|----------|
| `main.dart` (_OnboardingWrapper) | 🔴 High | MCP-V1 실행 |
| `family_sync_service.dart` | 🔴 High | MCP-V1, V4 실행 |
| `family_repository.dart` | 🔴 High | MCP-V1, V2 실행 |
| `record_provider.dart` | 🟡 Medium | MCP-V3 실행 |
| `onboarding_screen.dart` | 🔴 High | MCP-V1, V4 실행 |
| `003_family_sharing.sql` | 🔴 Critical | 전체 쿼리 실행 |

## 4. 실제 테스트 시나리오 (Claude Code 실행 가능)

### 시나리오 1: 앱 재설치 후 기존 데이터 접근

```bash
# Step 1: 현재 상태 확인
SELECT * FROM auth.users ORDER BY created_at DESC LIMIT 3;
SELECT * FROM family_members;

# Step 2: 앱 삭제 후 재설치 시뮬레이션
# (새 user가 auth.users에 생성됨)

# Step 3: 새 user와 family_members 매칭 확인
SELECT
  'auth.uid()' as source,
  '<new_user_id>' as user_id,
  (SELECT COUNT(*) FROM family_members WHERE user_id = '<new_user_id>') as in_family_members,
  (SELECT family_id FROM families WHERE user_id = '<old_user_id>') as expected_family;
```

### 시나리오 2: 초대 수락 후 기록 저장

```sql
-- 초대자(owner)가 만든 family에 피초대자(member)가 JOIN
-- 피초대자의 기록 저장 가능 여부 확인
SELECT is_family_member_or_legacy('<family_id>')
-- 이 쿼리를 피초대자 uid로 실행해야 함
```

## 5. 자동화 가능한 검증 스크립트

### pre-commit hook 제안 (수동 실행 권장)

```bash
#!/bin/bash
# rls-check.sh

echo "🔍 RLS 관련 파일 변경 감지..."

CHANGED_FILES=$(git diff --cached --name-only)

if echo "$CHANGED_FILES" | grep -qE "(family_repository|family_sync|main.dart|onboarding)"; then
  echo "⚠️ RLS 영향 파일 변경됨!"
  echo "📋 필수 검증:"
  echo "  1. Supabase MCP로 MCP-V1 쿼리 실행"
  echo "  2. 테스트 기기에서 실제 기록 저장 테스트"
  echo ""
  read -p "검증 완료? (y/n) " -n 1 -r
  if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    exit 1
  fi
fi
```

## 6. Claude Code 세션 시작 시 확인사항

### 새 세션 시작 체크리스트

```markdown
## RLS 작업 전 확인 (5초)

- [ ] Supabase MCP 연결됨?
- [ ] auth.users 현재 상태 확인했나?
- [ ] family_members 현재 상태 확인했나?
- [ ] 테스트 기기 준비됐나?
```

### 작업 완료 시 체크리스트

```markdown
## RLS 작업 완료 확인 (30초)

- [ ] MCP-V1 쿼리 실행 → 모든 user가 family_members에 있는가?
- [ ] 앱에서 실제 기록 저장 성공했나?
- [ ] 콘솔에 RLS 에러 없나?
- [ ] 다른 기록 유형(수유/수면/기저귀)도 테스트했나?
```

## 7. 이번 이슈의 근본 원인 재정리

```
┌──────────────────────────────────────────────────────────────┐
│ 근본 원인: "데이터 존재" ≠ "현재 사용자의 데이터 존재"        │
├──────────────────────────────────────────────────────────────┤
│                                                              │
│  ❌ 검증했던 것:                                              │
│     "families에 데이터가 있다"                                │
│     "babies에 데이터가 있다"                                  │
│     "RLS 함수가 정의되어 있다"                                │
│                                                              │
│  ✅ 검증했어야 했던 것:                                       │
│     "auth.uid()가 family_members에 있다"                     │
│     "is_family_member_or_legacy(family_id) = true"          │
│     "실제 INSERT가 성공한다"                                 │
│                                                              │
│  💡 핵심 교훈:                                                │
│     RLS는 "데이터"가 아닌 "권한"을 검증한다.                  │
│     권한 검증 = auth.uid() 기준                              │
│                                                              │
└──────────────────────────────────────────────────────────────┘
```

## 8. 추가 Edge Case (사용자 문서 보완)

### 사용자 문서에 없는 추가 케이스

| # | Edge Case | 발생 조건 | 예방 코드 위치 |
|---|-----------|----------|---------------|
| 7 | **iCloud Keychain 복원** | 새 기기에서 Keychain 복원 시 | `main.dart` |
| 8 | **TestFlight → App Store 전환** | 베타에서 정식 버전으로 전환 | `main.dart` |
| 9 | **Supabase 프로젝트 재생성** | 개발 중 DB 리셋 | 마이그레이션 스크립트 |
| 10 | **family_members 테이블 수동 삭제** | DB 정리 작업 중 실수 | RLS 정책에 fallback 추가 |

## 9. 권장 작업 순서 (Claude Code용)

```
1. 🔍 진단 (MCP 사용)
   └── auth.users, family_members, families 현재 상태 확인

2. 📝 계획
   └── 영향받는 파일 목록 작성
   └── 각 파일의 RLS 영향도 확인

3. 💻 구현
   └── family_members INSERT 누락 없는지 확인
   └── upsert 사용으로 중복 방지

4. ✅ 검증 (필수!)
   └── MCP-V1 쿼리로 매칭 확인
   └── 실제 앱에서 기록 저장 테스트
   └── 콘솔 로그 확인

5. 📋 문서화
   └── 변경 사항 CHANGELOG에 기록
   └── Edge case 발견 시 이 문서에 추가
```

---

**작성일**: 2026-02-04
**작성자**: Claude Code
**관련 이슈**: RLS 42501 에러 (activities INSERT 실패)
**해결 커밋**: main.dart 로컬 복원 시 family_members upsert 추가
