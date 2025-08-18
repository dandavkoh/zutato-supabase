-- =====================================================
-- ADD ADMIN MODERATION (RECIPES, RECIPE COMMENTS, USER MESSAGES, BLOG COMMENTS)
-- =====================================================
-- Grants admins abilities to read/edit/soft-delete (via is_deleted) where applicable
-- and adjusts RLS/policies accordingly.
-- 
-- Author: Grocery App Team
-- Date: 2024-01-11
-- =====================================================

-- Ensure helper exists
CREATE OR REPLACE FUNCTION current_user_is_admin()
RETURNS BOOLEAN AS $$
BEGIN
  RETURN EXISTS (
    SELECT 1 FROM public.user_settings us
    WHERE us.user_id = auth.uid()
      AND us.is_admin = TRUE
  );
END;
$$ LANGUAGE plpgsql STABLE SECURITY DEFINER SET search_path = public;

-- =====================================================
-- RECIPES: Admin read/update (soft delete via update)
-- =====================================================

-- Admins can read all recipes (including soft-deleted)
CREATE POLICY IF NOT EXISTS "Admins can read all recipes" ON recipes
  FOR SELECT USING (current_user_is_admin());

-- Admins can update any recipe (e.g., to soft-delete)
CREATE POLICY IF NOT EXISTS "Admins can update recipes" ON recipes
  FOR UPDATE USING (current_user_is_admin())
  WITH CHECK (current_user_is_admin());

-- =====================================================
-- RECIPE COMMENTS: Admin read/update (soft delete via update)
-- =====================================================

-- Admins can read all recipe comments
CREATE POLICY IF NOT EXISTS "Admins can read all recipe comments" ON recipe_comments
  FOR SELECT USING (current_user_is_admin());

-- Admins can update any recipe comment (e.g., to soft-delete or edit)
CREATE POLICY IF NOT EXISTS "Admins can update recipe comments" ON recipe_comments
  FOR UPDATE USING (current_user_is_admin())
  WITH CHECK (current_user_is_admin());

-- =====================================================
-- USER MESSAGES: Add soft-delete fields and admin moderation
-- =====================================================

-- Add soft-delete columns to user_messages
ALTER TABLE user_messages
  ADD COLUMN IF NOT EXISTS is_deleted BOOLEAN NOT NULL DEFAULT FALSE,
  ADD COLUMN IF NOT EXISTS deleted_at TIMESTAMP WITH TIME ZONE,
  ADD COLUMN IF NOT EXISTS deleted_by UUID REFERENCES auth.users(id);

-- Index for moderation filters
CREATE INDEX IF NOT EXISTS idx_user_messages_is_deleted ON user_messages(is_deleted);

-- Allow admins to read all messages
CREATE POLICY IF NOT EXISTS "Admins can read all user_messages" ON user_messages
  FOR SELECT USING (current_user_is_admin());

-- Allow admins to edit any message (including content) and soft-delete
CREATE POLICY IF NOT EXISTS "Admins can update user_messages" ON user_messages
  FOR UPDATE USING (current_user_is_admin())
  WITH CHECK (current_user_is_admin());

-- Relax the content update restriction for admins
CREATE OR REPLACE FUNCTION user_messages_restrict_updates()
RETURNS TRIGGER AS $$
BEGIN
  -- Admins may edit content; participants can only change flags
  IF NOT current_user_is_admin() THEN
    IF NEW.subject IS DISTINCT FROM OLD.subject OR
       NEW.body IS DISTINCT FROM OLD.body OR
       NEW.sender_id IS DISTINCT FROM OLD.sender_id OR
       NEW.recipient_id IS DISTINCT FROM OLD.recipient_id OR
       NEW.thread_id IS DISTINCT FROM OLD.thread_id THEN
      RAISE EXCEPTION 'Modifying message content or participants is not allowed';
    END IF;
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- =====================================================
-- BLOG COMMENTS: Admin moderation
-- =====================================================

-- Admins can update any blog comment (e.g., to soft-delete or edit)
CREATE POLICY IF NOT EXISTS "Admins can update blog comments" ON blog_comments
  FOR UPDATE USING (current_user_is_admin())
  WITH CHECK (current_user_is_admin());

-- Admins can read all blog comments (in case not already present)
CREATE POLICY IF NOT EXISTS "Admins can read all blog comments" ON blog_comments
  FOR SELECT USING (current_user_is_admin());

-- =====================================================
-- MIGRATION COMPLETE
-- =====================================================
-- ✅ Admins can edit/soft-delete recipes and recipe comments
-- ✅ Admins can read/edit/soft-delete user messages
-- ✅ Admins can read/edit/soft-delete blog comments
-- ✅ Policies added without enabling hard deletes

