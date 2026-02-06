-- HF3 롤백: 이전 마이그레이션 되돌리기
-- 문제: 원본 데이터가 이미 올바른 UTC였는데 -9시간을 잘못 적용함
-- 해결: +9시간으로 원복

-- 1. start_time 원복 (+9시간)
UPDATE activities
SET start_time = start_time + INTERVAL '9 hours'
WHERE start_time IS NOT NULL;

-- 2. end_time 원복 (+9시간)
UPDATE activities
SET end_time = end_time + INTERVAL '9 hours'
WHERE end_time IS NOT NULL;

-- 3. created_at 원복 (+9시간)
UPDATE activities
SET created_at = created_at + INTERVAL '9 hours'
WHERE created_at IS NOT NULL;

-- 4. updated_at 원복 (+9시간)
UPDATE activities
SET updated_at = updated_at + INTERVAL '9 hours'
WHERE updated_at IS NOT NULL;

-- 완료 메시지
DO $$
BEGIN
  RAISE NOTICE 'Rollback completed: +9 hours applied to restore original data';
END $$;
