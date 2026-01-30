-- ============================================
-- LULU MVP-F: Initial Database Schema
-- 다태아 중심 설계 (Multiple births first)
-- ============================================

-- Enable UUID extension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- ============================================
-- 1. families 테이블
-- 가족 단위 (1-4명의 아기 포함)
-- ============================================
CREATE TABLE IF NOT EXISTS families (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ
);

-- Index for faster user lookups
CREATE INDEX IF NOT EXISTS idx_families_user_id ON families(user_id);

-- ============================================
-- 2. babies 테이블
-- 개별 아기 정보 (다태아 지원)
-- ============================================
CREATE TABLE IF NOT EXISTS babies (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    family_id UUID NOT NULL REFERENCES families(id) ON DELETE CASCADE,
    name TEXT NOT NULL,
    birth_date DATE NOT NULL,
    gender TEXT CHECK (gender IN ('male', 'female', 'unknown')),
    gestational_weeks_at_birth INT CHECK (gestational_weeks_at_birth >= 22 AND gestational_weeks_at_birth <= 42),
    birth_weight_grams INT CHECK (birth_weight_grams >= 300 AND birth_weight_grams <= 6000),
    baby_type TEXT NOT NULL DEFAULT 'singleton' CHECK (baby_type IN ('singleton', 'twin', 'triplet', 'quadruplet')),
    zygosity TEXT CHECK (zygosity IN ('identical', 'fraternal', 'unknown')),
    birth_order INT CHECK (birth_order >= 1 AND birth_order <= 4),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ
);

-- Index for faster family lookups
CREATE INDEX IF NOT EXISTS idx_babies_family_id ON babies(family_id);

-- ============================================
-- 3. activities 테이블
-- 활동 기록 (다중 아기 동시 기록 지원)
-- ============================================
CREATE TABLE IF NOT EXISTS activities (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    family_id UUID NOT NULL REFERENCES families(id) ON DELETE CASCADE,
    baby_ids UUID[] NOT NULL, -- 다중 아기 지원 (배열)
    type TEXT NOT NULL CHECK (type IN ('sleep', 'feeding', 'diaper', 'play', 'health')),
    start_time TIMESTAMPTZ NOT NULL,
    end_time TIMESTAMPTZ,
    data JSONB, -- 활동별 추가 데이터 (수유량, 기저귀 종류 등)
    notes TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ
);

-- Indexes for faster lookups
CREATE INDEX IF NOT EXISTS idx_activities_family_id ON activities(family_id);
CREATE INDEX IF NOT EXISTS idx_activities_baby_ids ON activities USING GIN(baby_ids);
CREATE INDEX IF NOT EXISTS idx_activities_type ON activities(type);
CREATE INDEX IF NOT EXISTS idx_activities_start_time ON activities(start_time DESC);

-- ============================================
-- 4. Row Level Security (RLS)
-- 본인 데이터만 CRUD 가능
-- ============================================

-- Enable RLS on all tables
ALTER TABLE families ENABLE ROW LEVEL SECURITY;
ALTER TABLE babies ENABLE ROW LEVEL SECURITY;
ALTER TABLE activities ENABLE ROW LEVEL SECURITY;

-- Families: 본인 가족만 접근 가능
CREATE POLICY "Users can view own families"
    ON families FOR SELECT
    USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own families"
    ON families FOR INSERT
    WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own families"
    ON families FOR UPDATE
    USING (auth.uid() = user_id);

CREATE POLICY "Users can delete own families"
    ON families FOR DELETE
    USING (auth.uid() = user_id);

-- Babies: 본인 가족의 아기만 접근 가능
CREATE POLICY "Users can view own babies"
    ON babies FOR SELECT
    USING (
        family_id IN (
            SELECT id FROM families WHERE user_id = auth.uid()
        )
    );

CREATE POLICY "Users can insert own babies"
    ON babies FOR INSERT
    WITH CHECK (
        family_id IN (
            SELECT id FROM families WHERE user_id = auth.uid()
        )
    );

CREATE POLICY "Users can update own babies"
    ON babies FOR UPDATE
    USING (
        family_id IN (
            SELECT id FROM families WHERE user_id = auth.uid()
        )
    );

CREATE POLICY "Users can delete own babies"
    ON babies FOR DELETE
    USING (
        family_id IN (
            SELECT id FROM families WHERE user_id = auth.uid()
        )
    );

-- Activities: 본인 가족의 활동만 접근 가능
CREATE POLICY "Users can view own activities"
    ON activities FOR SELECT
    USING (
        family_id IN (
            SELECT id FROM families WHERE user_id = auth.uid()
        )
    );

CREATE POLICY "Users can insert own activities"
    ON activities FOR INSERT
    WITH CHECK (
        family_id IN (
            SELECT id FROM families WHERE user_id = auth.uid()
        )
    );

CREATE POLICY "Users can update own activities"
    ON activities FOR UPDATE
    USING (
        family_id IN (
            SELECT id FROM families WHERE user_id = auth.uid()
        )
    );

CREATE POLICY "Users can delete own activities"
    ON activities FOR DELETE
    USING (
        family_id IN (
            SELECT id FROM families WHERE user_id = auth.uid()
        )
    );

-- ============================================
-- 5. Trigger for updated_at
-- ============================================
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER update_families_updated_at
    BEFORE UPDATE ON families
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_babies_updated_at
    BEFORE UPDATE ON babies
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_activities_updated_at
    BEFORE UPDATE ON activities
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- ============================================
-- 6. Helper Functions
-- ============================================

-- 가족의 아기 수 확인 (최대 4명 제한)
CREATE OR REPLACE FUNCTION check_baby_limit()
RETURNS TRIGGER AS $$
BEGIN
    IF (SELECT COUNT(*) FROM babies WHERE family_id = NEW.family_id) >= 4 THEN
        RAISE EXCEPTION 'A family can have at most 4 babies';
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER enforce_baby_limit
    BEFORE INSERT ON babies
    FOR EACH ROW
    EXECUTE FUNCTION check_baby_limit();
