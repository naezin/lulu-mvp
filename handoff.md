# LULU MVP-F Handoff

**Version**: 16.0
**Updated**: 2026-02-13
**Sprint**: 24 Complete (main)

---

## 현재 상태

| 항목 | 값 |
|------|-----|
| Branch | `main` |
| App Version | `2.7.6+49` |
| Build | iOS 정상 (`flutter analyze` 에러 0개) |
| TestFlight | 업로드 성공 (2026-02-13) |
| Delivery UUID | `72d190fd-6e6d-4124-b63d-2d63592af960` |
| Merge Commit | `ab79416` (sprint-24 → main) |
| 이전 TestFlight | `2.7.5+48` |
| 안전 기준선 | `ab79416` (Sprint 24 merge) |

---

## Sprint 24 완료 내역

### 주요 변경사항

1. **C-0.4 SleepClassifier**: Pattern-based sleep type auto-classification (25 unit tests)
   - **동결됨**: split-night 오분류 근본 원인 발견 → Sprint 25 재설계
   - 임시: DB sleep_type + SleepTimeConfig.isNightTime fallback 사용
2. **C-0.6**: 놀이 그리드 → 깨시 그리드 교체
3. **C-5.1**: Sweet Spot 카드에 깨시 경과 + 참고 범위 추가
4. **sleep_type NULL 제거**: import/migration 소스에서 sleep_type 필수화
5. **napNumber 수정**: SleepClassifier → DB sleep_type 기반으로 전환
6. **HF-A**: 출생체중 → 성장 차트 첫 포인트 자동 생성 (메모리 전용)
7. **HF-B**: delta=0 → "전주와 동일" 표시
8. **HF-D**: calibrating 라벨 "일째" → "수면 N건 완료"

---

## 다음 세션에서 할 것

### Sprint 25 (계획)

- [ ] SleepClassifier 재설계 (sleep day grouping + anchor 알고리즘)
- [ ] WakeWindowStatistics → WeeklyStatistics 추가 (HF-C 해결)
- [ ] Growth DB 로드 구현 + 출생 측정 중복 방지
- [ ] Calibrating "앱 사용 N일" 기반 변경 (이슈 B)
- [ ] C-2: 노티피케이션 센터 UI
- [ ] C-6: 알림 인프라 (flutter_local_notifications)
- [ ] C-7: Sweet Spot 알림 체인

### 대기 중

- [ ] DB에 잔존하는 end_time=NULL 수면 레코드 정리
- [ ] 베타 테스터 피드백 수집
- [ ] Family Sharing 기능 테스트

---

## 주의사항 (다음 세션 참고)

1. **SleepClassifier 동결**: `sleep_classifier.dart` 수정 금지 (Sprint 25까지). 근본 원인: calendar date grouping으로 split-night 2nd chunk가 anchor를 2 AM으로 편향시킴.

2. **Growth auto-seed 메모리 전용**: `growth_provider.dart`의 birthWeight auto-seed는 앱 재시작마다 재생성됨. Sprint 25 DB 구현 시 중복 방지 필수.

3. **weekly_view.dart L389**: wakeWindow `change: 0` 하드코딩. Sprint 25 WakeWindowStatistics 추가 시 교체.

4. **해결 완료 코드 (건드리지 말 것)**:
   - `weekly_chart_full.dart`의 `_WeeklyGridPainter` 구조
   - `_navigateWeek`의 async/await 구조
   - `golden_band_bar.dart`의 `_GoldenBandPainter` 구조
   - `home_provider.dart` L291-299의 napNumber 로직

5. **미커밋 문서**: `CLAUDE.md`, `handoff.md`, `docs/work_instruction_template_v2.1.md`

---

## DB 스키마 (Sprint 24 기준, 변경 없음)

### 테이블

- **profiles** - 사용자 프로필
- **families** - 가족 정보 (user_id, created_by)
- **babies** - 아기 정보
- **activities** - 활동 기록 (sleep_type 필드: 'night'/'nap')
- **family_members** - 가족 멤버 관계 (UNIQUE: family_id + user_id)
- **family_invites** - 초대 코드 (6자리, 7일 유효)
- **badges** - 뱃지 달성 기록

### RLS 정책 (16개)

activities(4) + babies(4) + families(4) + badges(4) -- 모두 `is_family_member_or_legacy()` 기반

---

*"handoff.md = 세션 간 인수인계 문서. 매 세션 종료 시 반드시 업데이트."*
