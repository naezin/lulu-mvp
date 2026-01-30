-- ============================================
-- LULU MVP-F: Disable RLS for MVP Testing
-- MVP 테스트를 위한 RLS 임시 비활성화
--
-- ⚠️ WARNING: 프로덕션 배포 전 반드시 다시 활성화할 것!
-- ============================================

-- 기존 정책 삭제
DROP POLICY IF EXISTS "Users can view own families" ON families;
DROP POLICY IF EXISTS "Users can insert own families" ON families;
DROP POLICY IF EXISTS "Users can update own families" ON families;
DROP POLICY IF EXISTS "Users can delete own families" ON families;

DROP POLICY IF EXISTS "Users can view own babies" ON babies;
DROP POLICY IF EXISTS "Users can insert own babies" ON babies;
DROP POLICY IF EXISTS "Users can update own babies" ON babies;
DROP POLICY IF EXISTS "Users can delete own babies" ON babies;

DROP POLICY IF EXISTS "Users can view own activities" ON activities;
DROP POLICY IF EXISTS "Users can insert own activities" ON activities;
DROP POLICY IF EXISTS "Users can update own activities" ON activities;
DROP POLICY IF EXISTS "Users can delete own activities" ON activities;

-- RLS 비활성화
ALTER TABLE families DISABLE ROW LEVEL SECURITY;
ALTER TABLE babies DISABLE ROW LEVEL SECURITY;
ALTER TABLE activities DISABLE ROW LEVEL SECURITY;

-- anon 및 authenticated 역할에 모든 권한 부여
GRANT ALL ON families TO anon;
GRANT ALL ON families TO authenticated;
GRANT ALL ON babies TO anon;
GRANT ALL ON babies TO authenticated;
GRANT ALL ON activities TO anon;
GRANT ALL ON activities TO authenticated;

-- ============================================
-- MVP 테스트용 간단한 정책 (인증 없이 모든 접근 허용)
-- ============================================

-- 다시 RLS 활성화 (정책으로 제어)
ALTER TABLE families ENABLE ROW LEVEL SECURITY;
ALTER TABLE babies ENABLE ROW LEVEL SECURITY;
ALTER TABLE activities ENABLE ROW LEVEL SECURITY;

-- 모든 작업 허용 정책
CREATE POLICY "Allow all for MVP" ON families FOR ALL USING (true) WITH CHECK (true);
CREATE POLICY "Allow all for MVP" ON babies FOR ALL USING (true) WITH CHECK (true);
CREATE POLICY "Allow all for MVP" ON activities FOR ALL USING (true) WITH CHECK (true);
