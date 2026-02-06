-- 데이터 검증 쿼리
-- 롤백 후 실행하여 원본 BabyTime 데이터와 비교

-- 1. 2월 5일 데이터 조회 (UTC 기준으로 KST 2/5 00:00 ~ 2/6 00:00)
-- KST 2026-02-05 00:00 = UTC 2026-02-04 15:00
-- KST 2026-02-06 00:00 = UTC 2026-02-05 15:00

SELECT
  id,
  type,
  start_time,
  -- KST로 변환해서 표시
  start_time AT TIME ZONE 'UTC' AT TIME ZONE 'Asia/Seoul' as start_time_kst,
  end_time AT TIME ZONE 'UTC' AT TIME ZONE 'Asia/Seoul' as end_time_kst,
  data
FROM activities
WHERE start_time >= '2026-02-04 15:00:00+00'  -- KST 2/5 00:00
  AND start_time < '2026-02-05 15:00:00+00'   -- KST 2/6 00:00
ORDER BY start_time DESC;

-- 2. 원본 데이터 샘플 확인 (2026-02-05 08:39 PM KST = 분유 100ml)
-- UTC로 변환하면: 2026-02-05 11:39:00+00
SELECT
  id,
  type,
  start_time,
  start_time AT TIME ZONE 'UTC' AT TIME ZONE 'Asia/Seoul' as start_time_kst,
  data
FROM activities
WHERE type = 'feeding'
  AND start_time >= '2026-02-05 11:00:00+00'
  AND start_time <= '2026-02-05 12:00:00+00'
ORDER BY start_time DESC;

-- 3. 중복 데이터 확인
SELECT
  type,
  start_time,
  COUNT(*) as count
FROM activities
GROUP BY type, start_time
HAVING COUNT(*) > 1
ORDER BY count DESC;

-- 4. 2월 1일 ~ 2월 5일 전체 데이터 수 확인
SELECT
  DATE(start_time AT TIME ZONE 'UTC' AT TIME ZONE 'Asia/Seoul') as date_kst,
  type,
  COUNT(*) as count
FROM activities
WHERE start_time >= '2026-01-31 15:00:00+00'  -- KST 2/1 00:00
  AND start_time < '2026-02-05 15:00:00+00'   -- KST 2/6 00:00
GROUP BY DATE(start_time AT TIME ZONE 'UTC' AT TIME ZONE 'Asia/Seoul'), type
ORDER BY date_kst DESC, type;

-- 5. 특정 시간대 데이터 확인 (2026-02-05 08:39 PM KST 분유)
-- 롤백 전: 이 시간에 데이터가 없거나 다른 시간에 있을 것
-- 롤백 후: 2026-02-05 11:39:00 UTC에 존재해야 함
SELECT
  'Expected: 2026-02-05 08:39 PM KST (= 11:39 UTC)' as check_item,
  COUNT(*) as found
FROM activities
WHERE type = 'feeding'
  AND data->>'formulaAmount' = '100'
  AND start_time >= '2026-02-05 11:30:00+00'
  AND start_time <= '2026-02-05 11:45:00+00';
