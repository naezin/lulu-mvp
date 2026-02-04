-- ============================================
-- LULU: Family Sharing Migration (Safe Version)
-- 순환 참조 문제 해결 + 올바른 순서
-- ============================================

-- ============================================
-- 1. families 테이블 수정
-- ============================================
ALTER TABLE families
ADD COLUMN IF NOT EXISTS created_by UUID REFERENCES auth.users(id);

UPDATE families SET created_by = user_id WHERE created_by IS NULL;

-- ============================================
-- 2. family_members 테이블 생성 (RLS 비활성화 상태)
-- ============================================
CREATE TABLE IF NOT EXISTS family_members (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    family_id UUID NOT NULL REFERENCES families(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    role TEXT NOT NULL DEFAULT 'member' CHECK (role IN ('owner', 'member')),
    joined_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    UNIQUE (family_id, user_id)
);

CREATE INDEX IF NOT EXISTS idx_family_members_family_id ON family_members(family_id);
CREATE INDEX IF NOT EXISTS idx_family_members_user_id ON family_members(user_id);

-- ============================================
-- 3. family_invites 테이블 생성 (RLS 비활성화 상태)
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

CREATE INDEX IF NOT EXISTS idx_family_invites_code ON family_invites(invite_code);
CREATE INDEX IF NOT EXISTS idx_family_invites_family_id ON family_invites(family_id);

-- ============================================
-- 4. 기존 데이터 마이그레이션 (RLS 활성화 전!)
-- ============================================
INSERT INTO family_members (family_id, user_id, role, joined_at)
SELECT id, user_id, 'owner', COALESCE(created_at, NOW())
FROM families
WHERE user_id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM family_members fm
    WHERE fm.family_id = families.id AND fm.user_id = families.user_id
  );

-- ============================================
-- 5. 헬퍼 함수들 (RLS에서 사용)
-- ============================================

-- 5-1. 가족 멤버 확인 (SECURITY DEFINER로 RLS 우회)
CREATE OR REPLACE FUNCTION is_family_member(p_family_id UUID)
RETURNS BOOLEAN AS $$
BEGIN
    RETURN EXISTS (
        SELECT 1 FROM family_members
        WHERE family_id = p_family_id AND user_id = auth.uid()
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER STABLE;

-- 5-2. 가족 소유자 확인
CREATE OR REPLACE FUNCTION is_family_owner(p_family_id UUID)
RETURNS BOOLEAN AS $$
BEGIN
    RETURN EXISTS (
        SELECT 1 FROM family_members
        WHERE family_id = p_family_id AND user_id = auth.uid() AND role = 'owner'
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER STABLE;

-- ============================================
-- 6. RLS 정책 (순환 참조 방지)
-- ============================================

-- family_members RLS
ALTER TABLE family_members ENABLE ROW LEVEL SECURITY;

-- SELECT: 본인 레코드 또는 같은 가족 멤버
CREATE POLICY "fm_select" ON family_members FOR SELECT
    USING (
        user_id = auth.uid()  -- 본인 레코드는 항상 볼 수 있음
        OR is_family_member(family_id)  -- 같은 가족 멤버
    );

-- INSERT: 본인을 추가하거나 owner가 추가
CREATE POLICY "fm_insert" ON family_members FOR INSERT
    WITH CHECK (
        user_id = auth.uid()  -- 본인을 추가 (초대 수락 시)
        OR is_family_owner(family_id)  -- owner가 직접 추가
    );

-- DELETE: 본인이 나가거나 owner가 삭제
CREATE POLICY "fm_delete" ON family_members FOR DELETE
    USING (
        user_id = auth.uid()  -- 본인이 나가기
        OR is_family_owner(family_id)  -- owner가 삭제
    );

-- family_invites RLS
ALTER TABLE family_invites ENABLE ROW LEVEL SECURITY;

-- SELECT: 초대 코드로 조회 가능 (비인증도 가능하게)
CREATE POLICY "fi_select" ON family_invites FOR SELECT
    USING (true);  -- RPC에서 세부 검증

-- INSERT: owner만
CREATE POLICY "fi_insert" ON family_invites FOR INSERT
    WITH CHECK (is_family_owner(family_id));

-- UPDATE: 초대 수락 시 (used_at, used_by 업데이트)
CREATE POLICY "fi_update" ON family_invites FOR UPDATE
    USING (
        used_by = auth.uid()  -- 수락하는 사람
        OR is_family_owner(family_id)  -- owner
    );

-- DELETE: owner만
CREATE POLICY "fi_delete" ON family_invites FOR DELETE
    USING (is_family_owner(family_id));

-- ============================================
-- 7. RPC 함수들
-- ============================================

-- 7-1. 초대 정보 조회 (비인증 가능)
CREATE OR REPLACE FUNCTION get_invite_info(p_invite_code TEXT)
RETURNS JSONB AS $$
DECLARE
    v_invite RECORD;
    v_babies JSONB;
    v_member_count INT;
    v_clean_code TEXT;
BEGIN
    -- 코드 정규화 (대문자, 하이픈 제거)
    v_clean_code := UPPER(REPLACE(REPLACE(p_invite_code, '-', ''), ' ', ''));

    SELECT fi.*, f.created_at as family_created_at
    INTO v_invite
    FROM family_invites fi
    JOIN families f ON f.id = fi.family_id
    WHERE fi.invite_code = v_clean_code
      AND fi.used_at IS NULL
      AND fi.expires_at > NOW();

    IF NOT FOUND THEN
        RETURN jsonb_build_object('valid', false, 'error', 'INVALID_OR_EXPIRED');
    END IF;

    SELECT COUNT(*) INTO v_member_count
    FROM family_members WHERE family_id = v_invite.family_id;

    SELECT COALESCE(jsonb_agg(jsonb_build_object('id', id, 'name', name)), '[]'::jsonb)
    INTO v_babies
    FROM babies WHERE family_id = v_invite.family_id;

    RETURN jsonb_build_object(
        'valid', true,
        'familyId', v_invite.family_id,
        'memberCount', v_member_count,
        'babies', v_babies,
        'expiresAt', v_invite.expires_at
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 7-2. 초대 수락
CREATE OR REPLACE FUNCTION accept_invite(
    p_invite_code TEXT,
    p_baby_mappings JSONB DEFAULT NULL
)
RETURNS JSONB AS $$
DECLARE
    v_invite RECORD;
    v_family_id UUID;
    v_user_id UUID;
    v_clean_code TEXT;
    v_old_family_id UUID;
BEGIN
    v_user_id := auth.uid();
    IF v_user_id IS NULL THEN
        RETURN jsonb_build_object('success', false, 'error', 'NOT_AUTHENTICATED');
    END IF;

    v_clean_code := UPPER(REPLACE(REPLACE(p_invite_code, '-', ''), ' ', ''));

    SELECT * INTO v_invite
    FROM family_invites
    WHERE invite_code = v_clean_code
      AND used_at IS NULL
      AND expires_at > NOW();

    IF NOT FOUND THEN
        RETURN jsonb_build_object('success', false, 'error', 'INVALID_OR_EXPIRED');
    END IF;

    v_family_id := v_invite.family_id;

    -- 이미 멤버인지 확인
    IF EXISTS (SELECT 1 FROM family_members WHERE family_id = v_family_id AND user_id = v_user_id) THEN
        RETURN jsonb_build_object('success', false, 'error', 'ALREADY_MEMBER');
    END IF;

    -- 기존 가족에서 나가기
    SELECT family_id INTO v_old_family_id
    FROM family_members WHERE user_id = v_user_id LIMIT 1;

    DELETE FROM family_members WHERE user_id = v_user_id;

    -- 새 가족에 멤버로 추가
    INSERT INTO family_members (family_id, user_id, role)
    VALUES (v_family_id, v_user_id, 'member');

    -- 초대 코드 사용 처리
    UPDATE family_invites
    SET used_at = NOW(), used_by = v_user_id
    WHERE id = v_invite.id;

    -- 비어있는 기존 가족 정리
    IF v_old_family_id IS NOT NULL THEN
        DELETE FROM families
        WHERE id = v_old_family_id
          AND NOT EXISTS (SELECT 1 FROM family_members WHERE family_id = v_old_family_id);
    END IF;

    RETURN jsonb_build_object(
        'success', true,
        'familyId', v_family_id
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 7-3. 소유권 이전
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
        RETURN jsonb_build_object('success', false, 'error', 'NOT_AUTHENTICATED');
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM family_members
        WHERE family_id = p_family_id AND user_id = v_user_id AND role = 'owner'
    ) THEN
        RETURN jsonb_build_object('success', false, 'error', 'NOT_OWNER');
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM family_members
        WHERE family_id = p_family_id AND user_id = p_new_owner_id
    ) THEN
        RETURN jsonb_build_object('success', false, 'error', 'TARGET_NOT_MEMBER');
    END IF;

    UPDATE family_members SET role = 'member' WHERE family_id = p_family_id AND user_id = v_user_id;
    UPDATE family_members SET role = 'owner' WHERE family_id = p_family_id AND user_id = p_new_owner_id;

    RETURN jsonb_build_object('success', true);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 7-4. 가족 나가기
CREATE OR REPLACE FUNCTION leave_family(p_family_id UUID)
RETURNS JSONB AS $$
DECLARE
    v_user_id UUID;
    v_is_owner BOOLEAN;
    v_member_count INT;
BEGIN
    v_user_id := auth.uid();
    IF v_user_id IS NULL THEN
        RETURN jsonb_build_object('success', false, 'error', 'NOT_AUTHENTICATED');
    END IF;

    SELECT role = 'owner' INTO v_is_owner
    FROM family_members
    WHERE family_id = p_family_id AND user_id = v_user_id;

    IF NOT FOUND THEN
        RETURN jsonb_build_object('success', false, 'error', 'NOT_MEMBER');
    END IF;

    SELECT COUNT(*) INTO v_member_count
    FROM family_members WHERE family_id = p_family_id;

    IF v_is_owner AND v_member_count > 1 THEN
        RETURN jsonb_build_object('success', false, 'error', 'OWNER_CANNOT_LEAVE');
    END IF;

    DELETE FROM family_members WHERE family_id = p_family_id AND user_id = v_user_id;

    IF v_member_count = 1 THEN
        DELETE FROM families WHERE id = p_family_id;
    END IF;

    RETURN jsonb_build_object('success', true, 'familyDeleted', v_member_count = 1);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ============================================
-- 8. 검증 쿼리
-- ============================================
-- 실행 후 아래 쿼리로 확인:
-- SELECT table_name FROM information_schema.tables WHERE table_schema = 'public' AND table_name IN ('family_members', 'family_invites');
-- SELECT routine_name FROM information_schema.routines WHERE routine_schema = 'public' AND routine_name IN ('get_invite_info', 'accept_invite', 'transfer_ownership', 'leave_family', 'is_family_member', 'is_family_owner');
