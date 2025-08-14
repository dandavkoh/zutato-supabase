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
  is_admin BOOLEAN NOT NULL DEFAULT FALSE,
  feature_flags JSONB NOT NULL DEFAULT '{"is_pro_user": false}'::jsonb,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Enable Row Level Security
ALTER TABLE user_settings ENABLE ROW LEVEL SECURITY;

-- Indexes
CREATE INDEX idx_user_settings_is_admin ON user_settings(is_admin);
CREATE INDEX idx_user_settings_feature_flags_gin ON user_settings USING gin(feature_flags);

-- =====================================================
-- RLS POLICIES
-- =====================================================

-- Only the owning user can read their settings
CREATE POLICY "Users can read own settings" ON user_settings
  FOR SELECT USING (auth.uid() = user_id);

-- No INSERT/UPDATE/DELETE policies: rows are system-managed only

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
  -- Create user_settings with defaults
  INSERT INTO public.user_settings (user_id)
  VALUES (NEW.id)
  ON CONFLICT (user_id) DO NOTHING;
  
  -- Create public profile with defaults
  INSERT INTO public.public_user_profile (user_id)
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

-- =====================================================
-- PUBLIC USER PROFILE (READABLE BY EVERYONE)
-- =====================================================
-- Publicly readable table exposing minimal profile data
-- Independent of user_settings (no sync); created automatically on signup

-- Table with only public fields
CREATE TABLE public_user_profile (
  user_id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  nickname TEXT UNIQUE,
  social_links JSONB NOT NULL DEFAULT '{}'::jsonb,
  banner TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Enable Row Level Security
ALTER TABLE public_user_profile ENABLE ROW LEVEL SECURITY;

-- Everyone can read nicknames
CREATE POLICY "Everyone can read public_user_profile" ON public_user_profile
  FOR SELECT USING (true);

-- Only owner can update their profile; no deletes allowed
CREATE POLICY "Users can update own public_user_profile" ON public_user_profile
  FOR UPDATE USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

-- Timestamp trigger for public_user_nicknames
CREATE TRIGGER update_public_user_profile_updated_at BEFORE UPDATE ON public_user_profile
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- Indexes for public profile
CREATE INDEX idx_public_user_profile_nickname ON public_user_profile(nickname);
CREATE INDEX idx_public_user_profile_social_links_gin ON public_user_profile USING gin(social_links);