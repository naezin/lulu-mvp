-- ============================================
-- LULU: RLS Legacy Compatibility Fix + Auto Trigger
-- 2026-02-04 RLS 42501 에러 근본 해결
-- ============================================

-- ============================================
-- 1. Auto-create family_member Trigger
-- families INSERT 시 자동으로 family_members에 owner 등록
-- ============================================

CREATE OR REPLACE FUNCTION auto_create_family_member()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO family_members (family_id, user_id, role)
  VALUES (NEW.id, NEW.user_id, 'owner')
  ON CONFLICT (family_id, user_id) DO NOTHING;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS on_family_created ON families;
CREATE TRIGGER on_family_created
  AFTER INSERT ON families
  FOR EACH ROW
  EXECUTE FUNCTION auto_create_family_member();

-- ============================================
-- 2. Fix existing data (누락된 family_members 복구)
-- ============================================

INSERT INTO family_members (family_id, user_id, role)
SELECT id, user_id, 'owner'
FROM families f
WHERE NOT EXISTS (
  SELECT 1 FROM family_members fm
  WHERE fm.family_id = f.id
)
ON CONFLICT (family_id, user_id) DO NOTHING;

-- ============================================
-- 3. 레거시 호환 함수 생성
-- family_members OR families.user_id 둘 다 확인
-- ============================================

CREATE OR REPLACE FUNCTION is_family_member_or_legacy(p_family_id UUID)
RETURNS BOOLEAN AS $$
DECLARE
    v_uid UUID;
BEGIN
    v_uid := auth.uid();

    -- NULL 체크 (인증 안 됨)
    IF v_uid IS NULL THEN
        RETURN FALSE;
    END IF;

    -- 1. family_members에서 확인 (새 방식)
    IF EXISTS (
        SELECT 1 FROM family_members
        WHERE family_id = p_family_id AND user_id = v_uid
    ) THEN
        RETURN TRUE;
    END IF;

    -- 2. families.user_id에서 확인 (레거시)
    IF EXISTS (
        SELECT 1 FROM families
        WHERE id = p_family_id AND user_id = v_uid
    ) THEN
        RETURN TRUE;
    END IF;

    RETURN FALSE;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER STABLE;

-- ============================================
-- 2. 기존 RLS 정책 삭제
-- ============================================

-- activities 정책 삭제
DROP POLICY IF EXISTS "activity_select" ON activities;
DROP POLICY IF EXISTS "activity_insert" ON activities;
DROP POLICY IF EXISTS "activity_update" ON activities;
DROP POLICY IF EXISTS "activity_delete" ON activities;

-- babies 정책 삭제
DROP POLICY IF EXISTS "baby_select" ON babies;
DROP POLICY IF EXISTS "baby_insert" ON babies;
DROP POLICY IF EXISTS "baby_update" ON babies;
DROP POLICY IF EXISTS "baby_delete" ON babies;

-- families 정책 삭제
DROP POLICY IF EXISTS "family_select" ON families;
DROP POLICY IF EXISTS "family_insert" ON families;
DROP POLICY IF EXISTS "family_update" ON families;
DROP POLICY IF EXISTS "family_delete" ON families;

-- ============================================
-- 3. 새 RLS 정책 (레거시 호환)
-- ============================================

-- families RLS (레거시 호환)
CREATE POLICY "family_select" ON families FOR SELECT
    USING (is_family_member_or_legacy(id) OR user_id = auth.uid());

CREATE POLICY "family_insert" ON families FOR INSERT
    WITH CHECK (auth.uid() IS NOT NULL AND (created_by = auth.uid() OR user_id = auth.uid()));

CREATE POLICY "family_update" ON families FOR UPDATE
    USING (is_family_member_or_legacy(id) OR user_id = auth.uid());

CREATE POLICY "family_delete" ON families FOR DELETE
    USING (user_id = auth.uid());

-- babies RLS (레거시 호환)
CREATE POLICY "baby_select" ON babies FOR SELECT
    USING (is_family_member_or_legacy(family_id));

CREATE POLICY "baby_insert" ON babies FOR INSERT
    WITH CHECK (is_family_member_or_legacy(family_id));

CREATE POLICY "baby_update" ON babies FOR UPDATE
    USING (is_family_member_or_legacy(family_id));

CREATE POLICY "baby_delete" ON babies FOR DELETE
    USING (is_family_member_or_legacy(family_id));

-- activities RLS (레거시 호환)
CREATE POLICY "activity_select" ON activities FOR SELECT
    USING (is_family_member_or_legacy(family_id));

CREATE POLICY "activity_insert" ON activities FOR INSERT
    WITH CHECK (is_family_member_or_legacy(family_id));

CREATE POLICY "activity_update" ON activities FOR UPDATE
    USING (is_family_member_or_legacy(family_id));

CREATE POLICY "activity_delete" ON activities FOR DELETE
    USING (is_family_member_or_legacy(family_id));

-- ============================================
-- 4. 검증 쿼리
-- ============================================
-- 함수 확인: SELECT routine_name FROM information_schema.routines WHERE routine_name = 'is_family_member_or_legacy';
-- 정책 확인: SELECT tablename, policyname, cmd FROM pg_policies WHERE tablename IN ('families', 'babies', 'activities');
