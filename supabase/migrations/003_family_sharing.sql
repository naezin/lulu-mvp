-- ============================================
-- LULU: Family Sharing Migration
-- 가족 공유 기능을 위한 스키마 확장
-- ============================================

-- ============================================
-- 1. families 테이블 수정
-- created_by 컬럼 추가 (원래 소유자 추적용)
-- ============================================
ALTER TABLE families
ADD COLUMN IF NOT EXISTS created_by UUID REFERENCES auth.users(id);

-- 기존 데이터: user_id를 created_by로 복사
UPDATE families SET created_by = user_id WHERE created_by IS NULL;

-- NOT NULL 제약 추가
ALTER TABLE families ALTER COLUMN created_by SET NOT NULL;

-- ============================================
-- 2. family_members 테이블 (신규)
-- 가족 멤버 관리
-- ============================================
CREATE TABLE IF NOT EXISTS family_members (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    family_id UUID NOT NULL REFERENCES families(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    role TEXT NOT NULL DEFAULT 'member' CHECK (role IN ('owner', 'member')),
    joined_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    -- 같은 가족에 같은 사용자 중복 방지
    UNIQUE (family_id, user_id)
);

-- Indexes
CREATE INDEX IF NOT EXISTS idx_family_members_family_id ON family_members(family_id);
CREATE INDEX IF NOT EXISTS idx_family_members_user_id ON family_members(user_id);

-- ============================================
-- 3. family_invites 테이블 (신규)
-- 초대 코드 관리
-- ============================================
CREATE TABLE IF NOT EXISTS family_invites (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    family_id UUID NOT NULL REFERENCES families(id) ON DELETE CASCADE,
    invite_code TEXT NOT NULL UNIQUE,
    invited_email TEXT,
    created_by UUID NOT NULL REFERENCES auth.users(id),
    expires_at TIMESTAMPTZ NOT NULL,
    used_at TIMESTAMPTZ,
    used_by UUID REFERENCES auth.users(id),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Indexes
CREATE INDEX IF NOT EXISTS idx_family_invites_code ON family_invites(invite_code);
CREATE INDEX IF NOT EXISTS idx_family_invites_family_id ON family_invites(family_id);
CREATE INDEX IF NOT EXISTS idx_family_invites_expires_at ON family_invites(expires_at);

-- ============================================
-- 4. 기존 사용자 → family_members 마이그레이션
-- 기존 families.user_id 소유자를 family_members에 추가
-- ============================================
INSERT INTO family_members (family_id, user_id, role, joined_at)
SELECT id, user_id, 'owner', created_at
FROM families
WHERE NOT EXISTS (
    SELECT 1 FROM family_members fm
    WHERE fm.family_id = families.id AND fm.user_id = families.user_id
);

-- ============================================
-- 5. RLS 정책 업데이트
-- 가족 멤버 기반 접근 제어
-- ============================================

-- 기존 정책 삭제 (IF EXISTS로 안전하게)
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

-- 헬퍼 함수: 사용자가 가족 멤버인지 확인
CREATE OR REPLACE FUNCTION is_family_member(p_family_id UUID)
RETURNS BOOLEAN AS $$
BEGIN
    RETURN EXISTS (
        SELECT 1 FROM family_members
        WHERE family_id = p_family_id AND user_id = auth.uid()
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 헬퍼 함수: 사용자가 가족 소유자인지 확인
CREATE OR REPLACE FUNCTION is_family_owner(p_family_id UUID)
RETURNS BOOLEAN AS $$
BEGIN
    RETURN EXISTS (
        SELECT 1 FROM family_members
        WHERE family_id = p_family_id AND user_id = auth.uid() AND role = 'owner'
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- families RLS (멤버 기반)
CREATE POLICY "family_select" ON families FOR SELECT
    USING (is_family_member(id));

CREATE POLICY "family_insert" ON families FOR INSERT
    WITH CHECK (auth.uid() = created_by);

CREATE POLICY "family_update" ON families FOR UPDATE
    USING (is_family_owner(id));

CREATE POLICY "family_delete" ON families FOR DELETE
    USING (is_family_owner(id));

-- babies RLS (멤버 기반)
CREATE POLICY "baby_select" ON babies FOR SELECT
    USING (is_family_member(family_id));

CREATE POLICY "baby_insert" ON babies FOR INSERT
    WITH CHECK (is_family_member(family_id));

CREATE POLICY "baby_update" ON babies FOR UPDATE
    USING (is_family_member(family_id));

CREATE POLICY "baby_delete" ON babies FOR DELETE
    USING (is_family_owner(family_id));

-- activities RLS (멤버 기반)
CREATE POLICY "activity_select" ON activities FOR SELECT
    USING (is_family_member(family_id));

CREATE POLICY "activity_insert" ON activities FOR INSERT
    WITH CHECK (is_family_member(family_id));

CREATE POLICY "activity_update" ON activities FOR UPDATE
    USING (is_family_member(family_id));

CREATE POLICY "activity_delete" ON activities FOR DELETE
    USING (is_family_member(family_id));

-- family_members RLS
ALTER TABLE family_members ENABLE ROW LEVEL SECURITY;

CREATE POLICY "member_select" ON family_members FOR SELECT
    USING (is_family_member(family_id));

CREATE POLICY "member_insert" ON family_members FOR INSERT
    WITH CHECK (is_family_owner(family_id) OR auth.uid() = user_id);

CREATE POLICY "member_delete" ON family_members FOR DELETE
    USING (is_family_owner(family_id) OR auth.uid() = user_id);

-- family_invites RLS
ALTER TABLE family_invites ENABLE ROW LEVEL SECURITY;

CREATE POLICY "invite_select" ON family_invites FOR SELECT
    USING (is_family_member(family_id) OR invite_code IS NOT NULL);

CREATE POLICY "invite_insert" ON family_invites FOR INSERT
    WITH CHECK (is_family_owner(family_id));

CREATE POLICY "invite_update" ON family_invites FOR UPDATE
    USING (used_by = auth.uid() OR is_family_owner(family_id));

CREATE POLICY "invite_delete" ON family_invites FOR DELETE
    USING (is_family_owner(family_id));

-- ============================================
-- 6. RPC 함수들
-- ============================================

-- 6-1. 초대 수락 RPC
CREATE OR REPLACE FUNCTION accept_invite(
    p_invite_code TEXT,
    p_baby_mappings JSONB DEFAULT NULL
)
RETURNS JSONB AS $$
DECLARE
    v_invite RECORD;
    v_family_id UUID;
    v_user_id UUID;
    v_migrated_count INT := 0;
    v_old_family_id UUID;
    v_mapping JSONB;
BEGIN
    v_user_id := auth.uid();
    IF v_user_id IS NULL THEN
        RAISE EXCEPTION 'Not authenticated';
    END IF;

    -- 초대 코드 검증
    SELECT * INTO v_invite
    FROM family_invites
    WHERE invite_code = UPPER(REPLACE(p_invite_code, '-', ''))
      AND used_at IS NULL
      AND expires_at > NOW();

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Invalid or expired invite code';
    END IF;

    v_family_id := v_invite.family_id;

    -- 이미 멤버인지 확인
    IF EXISTS (SELECT 1 FROM family_members WHERE family_id = v_family_id AND user_id = v_user_id) THEN
        RAISE EXCEPTION 'Already a member of this family';
    END IF;

    -- 기존 가족 ID 저장 (기록 마이그레이션용)
    SELECT family_id INTO v_old_family_id
    FROM family_members
    WHERE user_id = v_user_id
    LIMIT 1;

    -- 기존 가족에서 나가기
    DELETE FROM family_members WHERE user_id = v_user_id;

    -- 새 가족에 멤버로 추가
    INSERT INTO family_members (family_id, user_id, role)
    VALUES (v_family_id, v_user_id, 'member');

    -- 초대 코드 사용 처리
    UPDATE family_invites
    SET used_at = NOW(), used_by = v_user_id
    WHERE id = v_invite.id;

    -- 기록 마이그레이션 (baby_mappings가 있는 경우)
    IF p_baby_mappings IS NOT NULL AND v_old_family_id IS NOT NULL THEN
        FOR v_mapping IN SELECT * FROM jsonb_array_elements(p_baby_mappings)
        LOOP
            UPDATE activities
            SET family_id = v_family_id,
                baby_ids = array_replace(
                    baby_ids,
                    (v_mapping->>'fromBabyId')::UUID,
                    (v_mapping->>'toBabyId')::UUID
                )
            WHERE family_id = v_old_family_id
              AND (v_mapping->>'fromBabyId')::UUID = ANY(baby_ids);

            v_migrated_count := v_migrated_count + 1;
        END LOOP;
    END IF;

    -- 비어있는 기존 가족 정리
    IF v_old_family_id IS NOT NULL THEN
        DELETE FROM families
        WHERE id = v_old_family_id
          AND NOT EXISTS (SELECT 1 FROM family_members WHERE family_id = v_old_family_id);
    END IF;

    RETURN jsonb_build_object(
        'success', true,
        'familyId', v_family_id,
        'migratedCount', v_migrated_count
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 6-2. 소유권 이전 RPC
CREATE OR REPLACE FUNCTION transfer_ownership(
    p_family_id UUID,
    p_new_owner_id UUID
)
RETURNS JSONB AS $$
DECLARE
    v_user_id UUID;
BEGIN
    v_user_id := auth.uid();
    IF v_user_id IS NULL THEN
        RAISE EXCEPTION 'Not authenticated';
    END IF;

    -- 현재 사용자가 소유자인지 확인
    IF NOT EXISTS (
        SELECT 1 FROM family_members
        WHERE family_id = p_family_id AND user_id = v_user_id AND role = 'owner'
    ) THEN
        RAISE EXCEPTION 'Not the owner of this family';
    END IF;

    -- 새 소유자가 멤버인지 확인
    IF NOT EXISTS (
        SELECT 1 FROM family_members
        WHERE family_id = p_family_id AND user_id = p_new_owner_id
    ) THEN
        RAISE EXCEPTION 'New owner is not a member of this family';
    END IF;

    -- 소유권 이전
    UPDATE family_members SET role = 'member' WHERE family_id = p_family_id AND user_id = v_user_id;
    UPDATE family_members SET role = 'owner' WHERE family_id = p_family_id AND user_id = p_new_owner_id;

    RETURN jsonb_build_object('success', true);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 6-3. 가족 나가기 RPC
CREATE OR REPLACE FUNCTION leave_family(p_family_id UUID)
RETURNS JSONB AS $$
DECLARE
    v_user_id UUID;
    v_is_owner BOOLEAN;
    v_member_count INT;
BEGIN
    v_user_id := auth.uid();
    IF v_user_id IS NULL THEN
        RAISE EXCEPTION 'Not authenticated';
    END IF;

    -- 멤버인지 확인
    SELECT role = 'owner' INTO v_is_owner
    FROM family_members
    WHERE family_id = p_family_id AND user_id = v_user_id;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Not a member of this family';
    END IF;

    -- 멤버 수 확인
    SELECT COUNT(*) INTO v_member_count
    FROM family_members
    WHERE family_id = p_family_id;

    -- 소유자이고 다른 멤버가 있으면 나갈 수 없음
    IF v_is_owner AND v_member_count > 1 THEN
        RAISE EXCEPTION 'Owner cannot leave while other members exist. Transfer ownership first.';
    END IF;

    -- 가족에서 나가기
    DELETE FROM family_members WHERE family_id = p_family_id AND user_id = v_user_id;

    -- 마지막 멤버였으면 가족 삭제
    IF v_member_count = 1 THEN
        DELETE FROM families WHERE id = p_family_id;
    END IF;

    RETURN jsonb_build_object('success', true, 'familyDeleted', v_member_count = 1);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 6-4. 초대 정보 조회 RPC (비인증 사용자도 조회 가능)
CREATE OR REPLACE FUNCTION get_invite_info(p_invite_code TEXT)
RETURNS JSONB AS $$
DECLARE
    v_invite RECORD;
    v_family RECORD;
    v_babies JSONB;
    v_member_count INT;
BEGIN
    -- 초대 코드 검증
    SELECT fi.*, f.created_at as family_created_at
    INTO v_invite
    FROM family_invites fi
    JOIN families f ON f.id = fi.family_id
    WHERE fi.invite_code = UPPER(REPLACE(p_invite_code, '-', ''))
      AND fi.used_at IS NULL
      AND fi.expires_at > NOW();

    IF NOT FOUND THEN
        RETURN jsonb_build_object('valid', false, 'error', 'Invalid or expired invite code');
    END IF;

    -- 멤버 수
    SELECT COUNT(*) INTO v_member_count
    FROM family_members
    WHERE family_id = v_invite.family_id;

    -- 아기 목록
    SELECT jsonb_agg(jsonb_build_object('id', id, 'name', name))
    INTO v_babies
    FROM babies
    WHERE family_id = v_invite.family_id;

    RETURN jsonb_build_object(
        'valid', true,
        'familyId', v_invite.family_id,
        'memberCount', v_member_count,
        'babies', COALESCE(v_babies, '[]'::jsonb),
        'expiresAt', v_invite.expires_at
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ============================================
-- 7. 만료된 초대 자동 정리 (선택적)
-- ============================================
-- Supabase pg_cron 또는 Edge Function으로 주기적 실행 권장
-- DELETE FROM family_invites WHERE expires_at < NOW() AND used_at IS NULL;
