-- =====================================================
-- ADD BLOG SYSTEM (ADMIN-ONLY AUTHORING, PUBLIC READING)
-- =====================================================
-- Admins (flagged via user_settings.is_admin) can create, edit, delete posts
-- Everyone can read published posts
-- Includes FTS + trigram indexes and normalized fields for a modern blog
--
-- Author: Grocery App Team
-- Date: 2024-01-09
-- =====================================================

-- Ensure required extension for trigram search
CREATE EXTENSION IF NOT EXISTS pg_trgm;

-- =====================================================
-- HELPER: Check if current user is admin
-- =====================================================

CREATE OR REPLACE FUNCTION current_user_is_admin()
RETURNS BOOLEAN AS $$
BEGIN
  RETURN EXISTS (
    SELECT 1
    FROM public.user_settings us
    WHERE us.user_id = auth.uid()
      AND us.is_admin = TRUE
  );
END;
$$ LANGUAGE plpgsql STABLE SECURITY DEFINER SET search_path = public;

-- =====================================================
-- HELPER: Estimate reading time in minutes (200 wpm)
-- =====================================================

CREATE OR REPLACE FUNCTION compute_reading_time_minutes(text)
RETURNS INTEGER AS $$
DECLARE
  word_count INTEGER;
BEGIN
  word_count := COALESCE(array_length(regexp_split_to_array($1, '\\s+'), 1), 0);
  RETURN GREATEST(1, CEIL(word_count::numeric / 200)::int);
END;
$$ LANGUAGE plpgsql IMMUTABLE;

-- =====================================================
-- BLOG_POSTS TABLE
-- =====================================================

CREATE TABLE blog_posts (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  slug TEXT NOT NULL UNIQUE,
  title TEXT NOT NULL,
  content TEXT NOT NULL,
  excerpt TEXT,
  cover_image_url TEXT NOT NULL,
  status TEXT NOT NULL CHECK (status IN ('draft', 'published', 'scheduled', 'archived')) DEFAULT 'draft',
  language TEXT NOT NULL DEFAULT 'de',
  meta_title TEXT,
  meta_description TEXT,
  published_at TIMESTAMP WITH TIME ZONE,
  scheduled_for TIMESTAMP WITH TIME ZONE,
  author_id UUID REFERENCES auth.users(id) ON DELETE SET NULL,
  reading_time_minutes INTEGER,
  fts tsvector GENERATED ALWAYS AS (
    to_tsvector('german', coalesce(title, '') || ' ' || coalesce(content, ''))
  ) STORED,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  is_deleted BOOLEAN DEFAULT FALSE,
  deleted_at TIMESTAMP WITH TIME ZONE,
  deleted_by UUID REFERENCES auth.users(id)
);

-- Enable Row Level Security
ALTER TABLE blog_posts ENABLE ROW LEVEL SECURITY;

-- =====================================================
-- INDEXES
-- =====================================================

CREATE INDEX idx_blog_posts_status_published_at ON blog_posts(status, published_at);
CREATE INDEX idx_blog_posts_author_id ON blog_posts(author_id);
CREATE INDEX idx_blog_posts_language ON blog_posts(language);
CREATE INDEX idx_blog_posts_created_at ON blog_posts(created_at);
CREATE INDEX idx_blog_posts_updated_at ON blog_posts(updated_at);
-- FTS and trigram for search
CREATE INDEX idx_blog_posts_fts ON blog_posts USING gin(fts);
CREATE INDEX idx_blog_posts_title_trgm ON blog_posts USING gin(title gin_trgm_ops);
CREATE INDEX idx_blog_posts_slug_trgm ON blog_posts USING gin(slug gin_trgm_ops);

-- =====================================================
-- TRIGGERS
-- =====================================================

-- Auto-update updated_at
CREATE TRIGGER update_blog_posts_updated_at BEFORE UPDATE ON blog_posts
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- Compute reading time and published_at defaults
CREATE OR REPLACE FUNCTION blog_posts_set_defaults()
RETURNS TRIGGER AS $$
BEGIN
  IF TG_OP = 'INSERT' THEN
    IF NEW.reading_time_minutes IS NULL THEN
      NEW.reading_time_minutes := compute_reading_time_minutes(COALESCE(NEW.content, ''));
    END IF;
    IF NEW.status = 'published' AND NEW.published_at IS NULL THEN
      NEW.published_at := NOW();
    END IF;
  ELSIF TG_OP = 'UPDATE' THEN
    IF NEW.content IS DISTINCT FROM OLD.content THEN
      NEW.reading_time_minutes := compute_reading_time_minutes(COALESCE(NEW.content, ''));
    END IF;
    IF NEW.status = 'published' AND OLD.status <> 'published' AND NEW.published_at IS NULL THEN
      NEW.published_at := NOW();
    END IF;
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER blog_posts_before_write
BEFORE INSERT OR UPDATE ON blog_posts
FOR EACH ROW EXECUTE FUNCTION blog_posts_set_defaults();

-- =====================================================
-- RLS POLICIES
-- =====================================================

-- Public can read published (and not deleted) posts whose publish date is in the past
CREATE POLICY "Public can read published blog_posts" ON blog_posts
  FOR SELECT USING (
    is_deleted = FALSE
    AND status = 'published'
    AND (published_at IS NULL OR published_at <= NOW())
  );

-- Admins can read all posts (any status)
CREATE POLICY "Admins can read all blog_posts" ON blog_posts
  FOR SELECT USING (current_user_is_admin());

-- Only admins can create posts; author_id must be the current user
CREATE POLICY "Admins can create blog_posts" ON blog_posts
  FOR INSERT WITH CHECK (current_user_is_admin() AND author_id = auth.uid());

-- Only admins can update posts
CREATE POLICY "Admins can update blog_posts" ON blog_posts
  FOR UPDATE USING (current_user_is_admin())
  WITH CHECK (current_user_is_admin());

-- Only admins can delete posts
CREATE POLICY "Admins can delete blog_posts" ON blog_posts
  FOR DELETE USING (current_user_is_admin());

-- =====================================================
-- BLOG COMMENTS
-- =====================================================

-- Table: blog_comments
CREATE TABLE blog_comments (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  post_id UUID REFERENCES blog_posts(id) ON DELETE CASCADE NOT NULL,
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
  parent_comment_id UUID REFERENCES blog_comments(id) ON DELETE CASCADE,
  comment TEXT NOT NULL,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  is_deleted BOOLEAN DEFAULT FALSE,
  deleted_at TIMESTAMP WITH TIME ZONE,
  deleted_by UUID REFERENCES auth.users(id)
);

-- Enable Row Level Security
ALTER TABLE blog_comments ENABLE ROW LEVEL SECURITY;

-- Indexes
CREATE INDEX idx_blog_comments_post_id ON blog_comments(post_id);
CREATE INDEX idx_blog_comments_user_id ON blog_comments(user_id);
CREATE INDEX idx_blog_comments_is_deleted ON blog_comments(is_deleted);
CREATE INDEX idx_blog_comments_created_at ON blog_comments(created_at);
CREATE INDEX idx_blog_comments_parent_comment_id ON blog_comments(parent_comment_id);

-- Triggers
CREATE TRIGGER update_blog_comments_updated_at BEFORE UPDATE ON blog_comments
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- RLS Policies

-- Everyone can read comments for publicly visible posts
CREATE POLICY "Everyone can read blog comments" ON blog_comments
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM blog_posts p
      WHERE p.id = blog_comments.post_id
        AND p.is_deleted = FALSE
        AND p.status = 'published'
        AND (p.published_at IS NULL OR p.published_at <= NOW())
    )
  );

-- Admins can read all comments
CREATE POLICY "Admins can read all blog comments" ON blog_comments
  FOR SELECT USING (current_user_is_admin());

-- Only authenticated users can create comments on publicly visible posts; user_id must match auth.uid()
CREATE POLICY "Authenticated users can create blog comments" ON blog_comments
  FOR INSERT WITH CHECK (
    auth.uid() = user_id AND
    EXISTS (
      SELECT 1 FROM blog_posts p
      WHERE p.id = blog_comments.post_id
        AND p.is_deleted = FALSE
        AND p.status = 'published'
        AND (p.published_at IS NULL OR p.published_at <= NOW())
    )
  );

-- Only the owner can update their comment (including soft delete)
CREATE POLICY "Users can update own blog comments" ON blog_comments
  FOR UPDATE USING (auth.uid() = user_id)
  WITH CHECK (
    auth.uid() = user_id AND
    EXISTS (
      SELECT 1 FROM blog_posts p
      WHERE p.id = blog_comments.post_id
        AND p.is_deleted = FALSE
        AND p.status = 'published'
        AND (p.published_at IS NULL OR p.published_at <= NOW())
    )
  );

-- No DELETE policy -> hard deletes are disallowed

-- Utility: Soft delete a blog comment
CREATE OR REPLACE FUNCTION soft_delete_blog_comment(comment_uuid UUID)
RETURNS VOID AS $$
BEGIN
  UPDATE blog_comments
  SET is_deleted = TRUE,
      deleted_at = NOW(),
      deleted_by = auth.uid()
  WHERE id = comment_uuid;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- =====================================================
-- TABLE: blog_comment_votes (upvotes for blog comments)
-- =====================================================

CREATE TABLE blog_comment_votes (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  comment_id UUID REFERENCES blog_comments(id) ON DELETE CASCADE NOT NULL,
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  UNIQUE(comment_id, user_id)
);

-- Enable Row Level Security
ALTER TABLE blog_comment_votes ENABLE ROW LEVEL SECURITY;

-- Indexes
CREATE INDEX idx_blog_comment_votes_comment_id ON blog_comment_votes(comment_id);
CREATE INDEX idx_blog_comment_votes_user_id ON blog_comment_votes(user_id);
CREATE INDEX idx_blog_comment_votes_created_at ON blog_comment_votes(created_at);

-- Triggers
CREATE TRIGGER update_blog_comment_votes_updated_at BEFORE UPDATE ON blog_comment_votes
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- RLS Policies

-- Everyone can read votes
CREATE POLICY "Everyone can read blog_comment_votes" ON blog_comment_votes
  FOR SELECT USING (true);

-- Only authenticated users can create votes; user_id must match auth.uid()
CREATE POLICY "Authenticated users can create blog_comment_votes" ON blog_comment_votes
  FOR INSERT WITH CHECK (auth.uid() = user_id);

-- Only the owner can update their vote
CREATE POLICY "Users can update own blog_comment_votes" ON blog_comment_votes
  FOR UPDATE USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

-- Only the owner can delete their vote
CREATE POLICY "Users can delete own blog_comment_votes" ON blog_comment_votes
  FOR DELETE USING (auth.uid() = user_id);

-- =====================================================
-- OPTIONAL VIEW: Public posts (convenient access)
-- =====================================================

CREATE OR REPLACE VIEW public_blog_posts AS
SELECT 
  id,
  slug,
  title,
  excerpt,
  cover_image_url,
  language,
  meta_title,
  meta_description,
  published_at,
  author_id,
  reading_time_minutes,
  created_at,
  updated_at
FROM blog_posts
WHERE is_deleted = FALSE
  AND status = 'published'
  AND (published_at IS NULL OR published_at <= NOW());

-- =====================================================
-- MIGRATION COMPLETE
-- =====================================================
-- The blog system is ready:
-- ✅ Admin-only authoring via user_settings.is_admin
-- ✅ Public read access to published posts
-- ✅ FTS + trigram indexes for future search needs
-- ✅ Automatic reading time and publish timestamp
-- ✅ SEO fields and slug for URLs
-- ✅ RLS hardened

