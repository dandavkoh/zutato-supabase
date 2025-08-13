-- =====================================================
-- ADD RECIPE RATINGS (1-5 STARS)
-- =====================================================
-- Users can rate recipes with 1-5 stars
-- Requirements:
-- - Only authenticated users can create ratings (once per recipe)
-- - Everyone can read ratings
-- - Users can only update their own ratings
-- - No hard delete; soft delete via is_deleted
-- - Track created_at and updated_at
--
-- Author: Grocery App Team
-- Date: 2024-01-07
-- =====================================================

-- =====================================================
-- TABLE: recipe_ratings
-- =====================================================

CREATE TABLE recipe_ratings (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  recipe_id UUID REFERENCES recipes(id) ON DELETE CASCADE NOT NULL,
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
  rating INTEGER NOT NULL CHECK (rating BETWEEN 1 AND 5),
  notes TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  is_deleted BOOLEAN DEFAULT FALSE,
  deleted_at TIMESTAMP WITH TIME ZONE,
  deleted_by UUID REFERENCES auth.users(id)
);

-- Enable Row Level Security
ALTER TABLE recipe_ratings ENABLE ROW LEVEL SECURITY;

-- =====================================================
-- INDEXES
-- =====================================================

CREATE INDEX idx_recipe_ratings_recipe_id ON recipe_ratings(recipe_id);
CREATE INDEX idx_recipe_ratings_user_id ON recipe_ratings(user_id);
CREATE INDEX idx_recipe_ratings_rating ON recipe_ratings(rating);
CREATE INDEX idx_recipe_ratings_is_deleted ON recipe_ratings(is_deleted);
CREATE INDEX idx_recipe_ratings_created_at ON recipe_ratings(created_at);

-- Enforce one active (not soft-deleted) rating per user per recipe
CREATE UNIQUE INDEX unique_active_rating_per_user_recipe
ON recipe_ratings(recipe_id, user_id)
WHERE is_deleted = FALSE;

-- =====================================================
-- TRIGGERS
-- =====================================================

-- Update updated_at on changes
CREATE TRIGGER update_recipe_ratings_updated_at BEFORE UPDATE ON recipe_ratings
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- =====================================================
-- RLS POLICIES
-- =====================================================

-- Everyone can read ratings (for non-deleted recipes)
CREATE POLICY "Everyone can read recipe ratings" ON recipe_ratings
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM recipes r
      WHERE r.id = recipe_ratings.recipe_id
        AND r.is_deleted = FALSE
    )
  );

-- Only authenticated users can create ratings for non-deleted recipes; user_id must match auth.uid()
CREATE POLICY "Authenticated users can create recipe ratings" ON recipe_ratings
  FOR INSERT WITH CHECK (
    auth.uid() = user_id AND
    EXISTS (
      SELECT 1 FROM recipes r
      WHERE r.id = recipe_ratings.recipe_id
        AND r.is_deleted = FALSE
    )
  );

-- Only the owner can update their rating (including soft delete)
CREATE POLICY "Users can update own recipe ratings" ON recipe_ratings
  FOR UPDATE USING (auth.uid() = user_id)
  WITH CHECK (
    auth.uid() = user_id AND
    EXISTS (
      SELECT 1 FROM recipes r
      WHERE r.id = recipe_ratings.recipe_id
        AND r.is_deleted = FALSE
    )
  );

-- No DELETE policy -> hard deletes are disallowed

-- =====================================================
-- UTILITY: Soft delete a recipe rating
-- =====================================================

CREATE OR REPLACE FUNCTION soft_delete_recipe_rating(rating_uuid UUID)
RETURNS VOID AS $$
BEGIN
  UPDATE recipe_ratings
  SET is_deleted = TRUE,
      deleted_at = NOW(),
      deleted_by = auth.uid()
  WHERE id = rating_uuid;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- =====================================================
-- TABLE: recipe_comments
-- =====================================================

CREATE TABLE recipe_comments (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  recipe_id UUID REFERENCES recipes(id) ON DELETE CASCADE NOT NULL,
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
  comment TEXT NOT NULL,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  is_deleted BOOLEAN DEFAULT FALSE,
  deleted_at TIMESTAMP WITH TIME ZONE,
  deleted_by UUID REFERENCES auth.users(id)
);

-- Enable Row Level Security
ALTER TABLE recipe_comments ENABLE ROW LEVEL SECURITY;

-- Indexes
CREATE INDEX idx_recipe_comments_recipe_id ON recipe_comments(recipe_id);
CREATE INDEX idx_recipe_comments_user_id ON recipe_comments(user_id);
CREATE INDEX idx_recipe_comments_is_deleted ON recipe_comments(is_deleted);
CREATE INDEX idx_recipe_comments_created_at ON recipe_comments(created_at);

-- Triggers
CREATE TRIGGER update_recipe_comments_updated_at BEFORE UPDATE ON recipe_comments
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- RLS Policies

-- Everyone can read comments (for non-deleted recipes)
CREATE POLICY "Everyone can read recipe comments" ON recipe_comments
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM recipes r
      WHERE r.id = recipe_comments.recipe_id
        AND r.is_deleted = FALSE
    )
  );

-- Only authenticated users can create comments for non-deleted recipes; user_id must match auth.uid()
CREATE POLICY "Authenticated users can create recipe comments" ON recipe_comments
  FOR INSERT WITH CHECK (
    auth.uid() = user_id AND
    EXISTS (
      SELECT 1 FROM recipes r
      WHERE r.id = recipe_comments.recipe_id
        AND r.is_deleted = FALSE
    )
  );

-- Only the owner can update their comment (including soft delete)
CREATE POLICY "Users can update own recipe comments" ON recipe_comments
  FOR UPDATE USING (auth.uid() = user_id)
  WITH CHECK (
    auth.uid() = user_id AND
    EXISTS (
      SELECT 1 FROM recipes r
      WHERE r.id = recipe_comments.recipe_id
        AND r.is_deleted = FALSE
    )
  );

-- No DELETE policy -> hard deletes are disallowed

-- Utility: Soft delete a recipe comment
CREATE OR REPLACE FUNCTION soft_delete_recipe_comment(comment_uuid UUID)
RETURNS VOID AS $$
BEGIN
  UPDATE recipe_comments
  SET is_deleted = TRUE,
      deleted_at = NOW(),
      deleted_by = auth.uid()
  WHERE id = comment_uuid;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;