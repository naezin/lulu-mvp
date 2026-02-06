-- HF3: UTC 시간대 마이그레이션
-- 문제: 기존 데이터가 로컬 시간(KST)을 UTC로 잘못 저장됨
-- 해결: 9시간을 빼서 정확한 UTC로 보정

-- 1. 백업 테이블 생성 (안전을 위해)
CREATE TABLE IF NOT EXISTS activities_backup_20260205 AS
SELECT * FROM activities;

-- 2. start_time 보정 (KST -> UTC = -9시간)
UPDATE activities
SET start_time = start_time - INTERVAL '9 hours'
WHERE start_time IS NOT NULL;

-- 3. end_time 보정
UPDATE activities
SET end_time = end_time - INTERVAL '9 hours'
WHERE end_time IS NOT NULL;

-- 4. created_at, updated_at 보정
UPDATE activities
SET created_at = created_at - INTERVAL '9 hours'
WHERE created_at IS NOT NULL;

UPDATE activities
SET updated_at = updated_at - INTERVAL '9 hours'
WHERE updated_at IS NOT NULL;

-- 완료 메시지
DO $$
BEGIN
  RAISE NOTICE 'UTC timezone migration completed. Backup table: activities_backup_20260205';
END $$;
