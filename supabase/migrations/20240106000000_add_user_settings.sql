-- =====================================================
-- ADD USER SETTINGS (NICKNAME + FEATURE FLAGS)
-- =====================================================
-- Per-user settings including a public nickname and feature flags
-- Privacy: Only the owning user can read/write their settings
--
-- Author: Grocery App Team
-- Date: 2024-01-06
-- =====================================================

-- =====================================================
-- USER_SETTINGS TABLE
-- =====================================================

CREATE TABLE user_settings (
  user_id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  nickname TEXT UNIQUE,
  show_ads BOOLEAN NOT NULL DEFAULT TRUE,
  feature_flags JSONB NOT NULL DEFAULT '{}',
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Enable Row Level Security
ALTER TABLE user_settings ENABLE ROW LEVEL SECURITY;

-- Indexes
CREATE INDEX idx_user_settings_show_ads ON user_settings(show_ads);
CREATE INDEX idx_user_settings_nickname ON user_settings(nickname);
CREATE INDEX idx_user_settings_feature_flags_gin ON user_settings USING gin(feature_flags);

-- =====================================================
-- RLS POLICIES
-- =====================================================

-- Only the owning user can read their settings
CREATE POLICY "Users can read own settings" ON user_settings
  FOR SELECT USING (auth.uid() = user_id);

-- Only the owning user can insert their settings row
CREATE POLICY "Users can create own settings" ON user_settings
  FOR INSERT WITH CHECK (auth.uid() = user_id);

-- Only the owning user can update their settings
CREATE POLICY "Users can update own settings" ON user_settings
  FOR UPDATE USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);

-- No delete policy -> nobody can delete

-- =====================================================
-- TRIGGERS
-- =====================================================

-- Update updated_at timestamp on changes
CREATE TRIGGER update_user_settings_updated_at BEFORE UPDATE ON user_settings
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- =====================================================
-- AUTO-CREATE USER SETTINGS ON SIGNUP
-- =====================================================
-- Creates a trigger on auth.users to insert a default user_settings row
-- Ensures every user has settings with default values right after registration

-- Function: create a user_settings row for each new auth user
CREATE OR REPLACE FUNCTION create_user_settings_for_new_user()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO public.user_settings (user_id)
  VALUES (NEW.id)
  ON CONFLICT (user_id) DO NOTHING;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

-- Trigger: run after a new user registers
DROP TRIGGER IF EXISTS on_auth_user_created_create_settings ON auth.users;
CREATE TRIGGER on_auth_user_created_create_settings
AFTER INSERT ON auth.users
FOR EACH ROW EXECUTE FUNCTION create_user_settings_for_new_user();