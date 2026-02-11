-- ============================================
-- LULU: Badge System Migration
-- Sprint 22 Badge-0: Achievement badges
-- ============================================

-- ============================================
-- 1. badges table
-- ============================================
CREATE TABLE IF NOT EXISTS badges (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    family_id UUID NOT NULL REFERENCES families(id) ON DELETE CASCADE,
    baby_id UUID REFERENCES babies(id) ON DELETE CASCADE,
    badge_key TEXT NOT NULL,
    tier TEXT NOT NULL DEFAULT 'normal' CHECK (tier IN ('normal', 'warm', 'tearful')),
    unlocked_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    activity_id UUID REFERENCES activities(id) ON DELETE SET NULL,
    data JSONB,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ============================================
-- 2. Partial unique indexes
-- NULL != NULL in PostgreSQL UNIQUE constraints,
-- so we need two partial indexes for baby_id.
-- ============================================

-- baby_id IS NOT NULL: one badge per key per baby per family
CREATE UNIQUE INDEX IF NOT EXISTS idx_badges_unique_with_baby
    ON badges (family_id, baby_id, badge_key)
    WHERE baby_id IS NOT NULL;

-- baby_id IS NULL: one badge per key per family (family-level badges)
CREATE UNIQUE INDEX IF NOT EXISTS idx_badges_unique_without_baby
    ON badges (family_id, badge_key)
    WHERE baby_id IS NULL;

-- Query indexes
CREATE INDEX IF NOT EXISTS idx_badges_family_id ON badges(family_id);
CREATE INDEX IF NOT EXISTS idx_badges_baby_id ON badges(baby_id);
CREATE INDEX IF NOT EXISTS idx_badges_badge_key ON badges(badge_key);

-- ============================================
-- 3. RLS (same pattern as activities)
-- ============================================
ALTER TABLE badges ENABLE ROW LEVEL SECURITY;

CREATE POLICY "badge_select" ON badges FOR SELECT
    USING (is_family_member_or_legacy(family_id));

CREATE POLICY "badge_insert" ON badges FOR INSERT
    WITH CHECK (is_family_member_or_legacy(family_id));

CREATE POLICY "badge_update" ON badges FOR UPDATE
    USING (is_family_member_or_legacy(family_id));

CREATE POLICY "badge_delete" ON badges FOR DELETE
    USING (is_family_member_or_legacy(family_id));

-- ============================================
-- 4. Verification queries
-- ============================================
-- Run after migration:
-- SELECT tablename FROM pg_tables WHERE tablename = 'badges';
-- SELECT indexname FROM pg_indexes WHERE tablename = 'badges';
-- SELECT policyname FROM pg_policies WHERE tablename = 'badges';
