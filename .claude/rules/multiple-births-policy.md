# Multiple Births Policy (MVP-F)

## 다태아 중심 설계 원칙

### 1. 단태아 가정 금지

```dart
// WRONG: 단태아 가정
final baby = babyProvider.currentBaby;  // 단일 아기만 가정

// CORRECT: 다태아 고려
final family = familyProvider.currentFamily;
final babies = family.babies;
final selectedBaby = babies.firstWhere((b) => b.id == selectedBabyId);
```

### 2. 교정연령 개별 계산

각 아기마다 독립적으로 교정연령을 계산해야 합니다.

```dart
// 아기별 교정연령 사용
for (final baby in babies) {
  final correctedAge = baby.correctedAgeInMonths;
  // 아기별 처리
}
```

### 3. 개별 기록 (v5.0 - "둘 다" 버튼 제거됨)

**⚠️ "둘 다" 버튼은 v5.0에서 제거됨!**

```dart
// WRONG: "둘 다" 지원 (제거됨)
Future<void> saveActivity({
  required List<String> babyIds,  // ❌ 제거됨
  // ...
});

// CORRECT: 개별 기록
Future<void> saveActivity({
  required String babyId,  // ✅ 단일 아기 ID
  // ...
});
```

**대안**: BabyTabBar로 빠른 탭 전환 (< 1초) + QuickRecordButton ("이전과 같이")

### 4. UI 고려사항

- BabyTabBar: 아기 전환 탭 (상단) - 교정연령 통합 표시
- QuickRecordButton: "이전과 같이" 빠른 기록
- 아기별 색상 구분 (LuluColors.babyColors)
- **BabySelector: 삭제됨 (v5.0)**

## 금지 표현

- 쌍둥이 "우열" 비교 금지
- "정상/비정상" 판단 표현 금지
- "첫째가 더 잘한다" 등 비교 문구 금지
- "둘 다" 버튼 (v5.0 제거됨)

---

## RLS 관련 주의사항 (2026-02-04 추가)

### family_members 필수 등록

다태아 가족 생성 시 반드시 `family_members`에 owner 등록:

```dart
// WRONG: families만 INSERT
await supabase.from('families').insert({
  'user_id': userId,
});
// ❌ RLS 에러 발생!

// CORRECT: families + family_members 함께
await supabase.from('families').insert({...});
await supabase.from('family_members').insert({
  'family_id': familyId,
  'user_id': userId,
  'role': 'owner',
});
// ✅ RLS 통과
```

### Apple Sign-In 주의

- 앱 재설치 시 새 uid 생성됨
- 기존 family_members에 없으면 RLS 에러
- main.dart에서 upsert로 자동 처리됨
