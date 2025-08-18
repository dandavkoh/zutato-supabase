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
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies 
    WHERE schemaname = 'public' AND tablename = 'recipes' AND policyname = 'Admins can read all recipes'
  ) THEN
    EXECUTE 'CREATE POLICY "Admins can read all recipes" ON public.recipes FOR SELECT USING (current_user_is_admin())';
  END IF;
END$$;

-- Admins can update any recipe (e.g., to soft-delete)
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies 
    WHERE schemaname = 'public' AND tablename = 'recipes' AND policyname = 'Admins can update recipes'
  ) THEN
    EXECUTE 'CREATE POLICY "Admins can update recipes" ON public.recipes FOR UPDATE USING (current_user_is_admin()) WITH CHECK (current_user_is_admin())';
  END IF;
END$$;

-- =====================================================
-- RECIPE COMMENTS: Admin read/update (soft delete via update)
-- =====================================================

-- Admins can read all recipe comments
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies 
    WHERE schemaname = 'public' AND tablename = 'recipe_comments' AND policyname = 'Admins can read all recipe comments'
  ) THEN
    EXECUTE 'CREATE POLICY "Admins can read all recipe comments" ON public.recipe_comments FOR SELECT USING (current_user_is_admin())';
  END IF;
END$$;

-- Admins can update any recipe comment (e.g., to soft-delete or edit)
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies 
    WHERE schemaname = 'public' AND tablename = 'recipe_comments' AND policyname = 'Admins can update recipe comments'
  ) THEN
    EXECUTE 'CREATE POLICY "Admins can update recipe comments" ON public.recipe_comments FOR UPDATE USING (current_user_is_admin()) WITH CHECK (current_user_is_admin())';
  END IF;
END$$;

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
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies 
    WHERE schemaname = 'public' AND tablename = 'user_messages' AND policyname = 'Admins can read all user_messages'
  ) THEN
    EXECUTE 'CREATE POLICY "Admins can read all user_messages" ON public.user_messages FOR SELECT USING (current_user_is_admin())';
  END IF;
END$$;

-- Allow admins to edit any message (including content) and soft-delete
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies 
    WHERE schemaname = 'public' AND tablename = 'user_messages' AND policyname = 'Admins can update user_messages'
  ) THEN
    EXECUTE 'CREATE POLICY "Admins can update user_messages" ON public.user_messages FOR UPDATE USING (current_user_is_admin()) WITH CHECK (current_user_is_admin())';
  END IF;
END$$;

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
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies 
    WHERE schemaname = 'public' AND tablename = 'blog_comments' AND policyname = 'Admins can update blog comments'
  ) THEN
    EXECUTE 'CREATE POLICY "Admins can update blog comments" ON public.blog_comments FOR UPDATE USING (current_user_is_admin()) WITH CHECK (current_user_is_admin())';
  END IF;
END$$;

-- Admins can read all blog comments (in case not already present)
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies 
    WHERE schemaname = 'public' AND tablename = 'blog_comments' AND policyname = 'Admins can read all blog comments'
  ) THEN
    EXECUTE 'CREATE POLICY "Admins can read all blog comments" ON public.blog_comments FOR SELECT USING (current_user_is_admin())';
  END IF;
END$$;

-- =====================================================
-- CONTENT REPORTS (moved in from separate migration)
-- =====================================================

-- TABLE: content_reports (polymorphic via mutually exclusive FKs)
CREATE TABLE IF NOT EXISTS content_reports (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  recipe_id UUID REFERENCES recipes(id) ON DELETE CASCADE,
  recipe_comment_id UUID REFERENCES recipe_comments(id) ON DELETE CASCADE,
  user_message_id UUID REFERENCES user_messages(id) ON DELETE CASCADE,
  forum_thread_id UUID REFERENCES forum_threads(id) ON DELETE CASCADE,
  forum_post_id UUID REFERENCES forum_posts(id) ON DELETE CASCADE,
  blog_comment_id UUID REFERENCES blog_comments(id) ON DELETE CASCADE,
  reported_by UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
  reason TEXT NOT NULL,
  details TEXT,
  status TEXT NOT NULL DEFAULT 'open' CHECK (status IN ('open','in_review','resolved','rejected')),
  resolution_notes TEXT,
  resolved_by UUID REFERENCES auth.users(id),
  resolved_at TIMESTAMP WITH TIME ZONE,
  is_deleted BOOLEAN NOT NULL DEFAULT FALSE,
  deleted_at TIMESTAMP WITH TIME ZONE,
  deleted_by UUID REFERENCES auth.users(id),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  CONSTRAINT exactly_one_target_set CHECK (
    (recipe_id IS NOT NULL)::int +
    (recipe_comment_id IS NOT NULL)::int +
    (user_message_id IS NOT NULL)::int +
    (forum_thread_id IS NOT NULL)::int +
    (forum_post_id IS NOT NULL)::int +
    (blog_comment_id IS NOT NULL)::int = 1
  )
);

ALTER TABLE content_reports ENABLE ROW LEVEL SECURITY;

-- Indexes
CREATE INDEX IF NOT EXISTS idx_content_reports_reported_by ON content_reports(reported_by);
CREATE INDEX IF NOT EXISTS idx_content_reports_status ON content_reports(status);
CREATE INDEX IF NOT EXISTS idx_content_reports_created_at ON content_reports(created_at);
CREATE INDEX IF NOT EXISTS idx_content_reports_is_deleted ON content_reports(is_deleted);
CREATE INDEX IF NOT EXISTS idx_content_reports_recipe_id ON content_reports(recipe_id);
CREATE INDEX IF NOT EXISTS idx_content_reports_recipe_comment_id ON content_reports(recipe_comment_id);
CREATE INDEX IF NOT EXISTS idx_content_reports_user_message_id ON content_reports(user_message_id);
CREATE INDEX IF NOT EXISTS idx_content_reports_forum_thread_id ON content_reports(forum_thread_id);
CREATE INDEX IF NOT EXISTS idx_content_reports_forum_post_id ON content_reports(forum_post_id);
CREATE INDEX IF NOT EXISTS idx_content_reports_blog_comment_id ON content_reports(blog_comment_id);

-- Prevent duplicate active reports per user per target
CREATE UNIQUE INDEX IF NOT EXISTS unique_active_report_per_user_recipe
ON content_reports(recipe_id, reported_by)
WHERE recipe_id IS NOT NULL AND is_deleted = FALSE;

CREATE UNIQUE INDEX IF NOT EXISTS unique_active_report_per_user_recipe_comment
ON content_reports(recipe_comment_id, reported_by)
WHERE recipe_comment_id IS NOT NULL AND is_deleted = FALSE;

CREATE UNIQUE INDEX IF NOT EXISTS unique_active_report_per_user_user_message
ON content_reports(user_message_id, reported_by)
WHERE user_message_id IS NOT NULL AND is_deleted = FALSE;

CREATE UNIQUE INDEX IF NOT EXISTS unique_active_report_per_user_forum_thread
ON content_reports(forum_thread_id, reported_by)
WHERE forum_thread_id IS NOT NULL AND is_deleted = FALSE;

CREATE UNIQUE INDEX IF NOT EXISTS unique_active_report_per_user_forum_post
ON content_reports(forum_post_id, reported_by)
WHERE forum_post_id IS NOT NULL AND is_deleted = FALSE;

CREATE UNIQUE INDEX IF NOT EXISTS unique_active_report_per_user_blog_comment
ON content_reports(blog_comment_id, reported_by)
WHERE blog_comment_id IS NOT NULL AND is_deleted = FALSE;

-- Triggers
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_trigger 
    WHERE tgname = 'update_content_reports_updated_at' 
      AND tgrelid = 'public.content_reports'::regclass
  ) THEN
    EXECUTE 'CREATE TRIGGER update_content_reports_updated_at BEFORE UPDATE ON public.content_reports FOR EACH ROW EXECUTE FUNCTION update_updated_at_column()';
  END IF;
END$$;

-- RLS POLICIES
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies 
    WHERE schemaname = 'public' AND tablename = 'content_reports' AND policyname = 'Reporters can read own content_reports'
  ) THEN
    EXECUTE 'CREATE POLICY "Reporters can read own content_reports" ON public.content_reports FOR SELECT USING (auth.uid() = reported_by)';
  END IF;
END$$;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies 
    WHERE schemaname = 'public' AND tablename = 'content_reports' AND policyname = 'Admins can read all content_reports'
  ) THEN
    EXECUTE 'CREATE POLICY "Admins can read all content_reports" ON public.content_reports FOR SELECT USING (current_user_is_admin())';
  END IF;
END$$;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies 
    WHERE schemaname = 'public' AND tablename = 'content_reports' AND policyname = 'Authenticated users can create content_reports'
  ) THEN
    EXECUTE 'CREATE POLICY "Authenticated users can create content_reports" ON public.content_reports FOR INSERT WITH CHECK (
    auth.uid() = reported_by AND (
      (recipe_id IS NOT NULL AND EXISTS (
        SELECT 1 FROM recipes r WHERE r.id = recipe_id AND r.is_deleted = FALSE
      )) OR
      (recipe_comment_id IS NOT NULL AND EXISTS (
        SELECT 1 FROM recipe_comments rc
        JOIN recipes r ON r.id = rc.recipe_id
        WHERE rc.id = recipe_comment_id AND rc.is_deleted = FALSE AND r.is_deleted = FALSE
      )) OR
      (user_message_id IS NOT NULL AND EXISTS (
        SELECT 1 FROM user_messages m
        WHERE m.id = user_message_id AND auth.uid() IN (m.sender_id, m.recipient_id)
      )) OR
      (forum_thread_id IS NOT NULL AND EXISTS (
        SELECT 1 FROM forum_threads t
        WHERE t.id = forum_thread_id AND t.is_deleted = FALSE
      )) OR
      (forum_post_id IS NOT NULL AND EXISTS (
        SELECT 1 FROM forum_posts p
        JOIN forum_threads t ON t.id = p.thread_id
        WHERE p.id = forum_post_id AND p.is_deleted = FALSE AND t.is_deleted = FALSE
      )) OR
      (blog_comment_id IS NOT NULL AND EXISTS (
        SELECT 1 FROM blog_comments bc
        JOIN blog_posts bp ON bp.id = bc.post_id
        WHERE bc.id = blog_comment_id AND bc.is_deleted = FALSE AND bp.is_deleted = FALSE
          AND bp.status = ''published'' AND (bp.published_at IS NULL OR bp.published_at <= NOW())
      ))
    )
  )';
  END IF;
END$$;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies 
    WHERE schemaname = 'public' AND tablename = 'content_reports' AND policyname = 'Admins can update content_reports'
  ) THEN
    EXECUTE 'CREATE POLICY "Admins can update content_reports" ON public.content_reports FOR UPDATE USING (current_user_is_admin()) WITH CHECK (current_user_is_admin())';
  END IF;
END$$;

-- =====================================================
-- ADMIN OVERRIDES FOR RECIPE SUBTABLES (SECTIONS, INGREDIENTS, STEPS)
-- =====================================================

-- recipe_ingredient_sections
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies
    WHERE schemaname = 'public' AND tablename = 'recipe_ingredient_sections' AND policyname = 'Admins can insert recipe sections'
  ) THEN
    EXECUTE 'CREATE POLICY "Admins can insert recipe sections" ON public.recipe_ingredient_sections FOR INSERT WITH CHECK (current_user_is_admin())';
  END IF;
END$$;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies
    WHERE schemaname = 'public' AND tablename = 'recipe_ingredient_sections' AND policyname = 'Admins can update recipe sections'
  ) THEN
    EXECUTE 'CREATE POLICY "Admins can update recipe sections" ON public.recipe_ingredient_sections FOR UPDATE USING (current_user_is_admin()) WITH CHECK (current_user_is_admin())';
  END IF;
END$$;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies
    WHERE schemaname = 'public' AND tablename = 'recipe_ingredient_sections' AND policyname = 'Admins can delete recipe sections'
  ) THEN
    EXECUTE 'CREATE POLICY "Admins can delete recipe sections" ON public.recipe_ingredient_sections FOR DELETE USING (current_user_is_admin())';
  END IF;
END$$;

-- recipe_ingredients
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies
    WHERE schemaname = 'public' AND tablename = 'recipe_ingredients' AND policyname = 'Admins can insert recipe ingredients'
  ) THEN
    EXECUTE 'CREATE POLICY "Admins can insert recipe ingredients" ON public.recipe_ingredients FOR INSERT WITH CHECK (current_user_is_admin())';
  END IF;
END$$;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies
    WHERE schemaname = 'public' AND tablename = 'recipe_ingredients' AND policyname = 'Admins can update recipe ingredients'
  ) THEN
    EXECUTE 'CREATE POLICY "Admins can update recipe ingredients" ON public.recipe_ingredients FOR UPDATE USING (current_user_is_admin()) WITH CHECK (current_user_is_admin())';
  END IF;
END$$;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies
    WHERE schemaname = 'public' AND tablename = 'recipe_ingredients' AND policyname = 'Admins can delete recipe ingredients'
  ) THEN
    EXECUTE 'CREATE POLICY "Admins can delete recipe ingredients" ON public.recipe_ingredients FOR DELETE USING (current_user_is_admin())';
  END IF;
END$$;

-- recipe_steps
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies
    WHERE schemaname = 'public' AND tablename = 'recipe_steps' AND policyname = 'Admins can insert recipe steps'
  ) THEN
    EXECUTE 'CREATE POLICY "Admins can insert recipe steps" ON public.recipe_steps FOR INSERT WITH CHECK (current_user_is_admin())';
  END IF;
END$$;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies
    WHERE schemaname = 'public' AND tablename = 'recipe_steps' AND policyname = 'Admins can update recipe steps'
  ) THEN
    EXECUTE 'CREATE POLICY "Admins can update recipe steps" ON public.recipe_steps FOR UPDATE USING (current_user_is_admin()) WITH CHECK (current_user_is_admin())';
  END IF;
END$$;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies
    WHERE schemaname = 'public' AND tablename = 'recipe_steps' AND policyname = 'Admins can delete recipe steps'
  ) THEN
    EXECUTE 'CREATE POLICY "Admins can delete recipe steps" ON public.recipe_steps FOR DELETE USING (current_user_is_admin())';
  END IF;
END$$;

-- =====================================================
-- MIGRATION COMPLETE
-- =====================================================
-- ✅ Admins can edit/soft-delete recipes and recipe comments
-- ✅ Admins can read/edit/soft-delete user messages
-- ✅ Admins can read/edit/soft-delete blog comments
-- ✅ Policies added without enabling hard deletes

