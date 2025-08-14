-- =====================================================
-- ADD USER COOKBOOK (FAVORITES) FOR RECIPES
-- =====================================================
-- Users can add/remove recipes to their personal cookbook (favorites)
-- - Only the owner can read their favorites
-- - Only the owner can add/remove their favorites
-- - No updates needed
--
-- Author: Grocery App Team
-- Date: 2024-01-08
-- =====================================================

-- =====================================================
-- TABLE: user_cookbook_recipes
-- =====================================================

CREATE TABLE user_cookbook_recipes (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
  recipe_id UUID REFERENCES recipes(id) ON DELETE CASCADE NOT NULL,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  UNIQUE(user_id, recipe_id)
);

-- Enable Row Level Security
ALTER TABLE user_cookbook_recipes ENABLE ROW LEVEL SECURITY;

-- Indexes
CREATE INDEX idx_user_cookbook_recipes_user_id ON user_cookbook_recipes(user_id);
CREATE INDEX idx_user_cookbook_recipes_recipe_id ON user_cookbook_recipes(recipe_id);
CREATE INDEX idx_user_cookbook_recipes_created_at ON user_cookbook_recipes(created_at);

-- =====================================================
-- RLS POLICIES
-- =====================================================

-- Only the owning user can read their favorites
CREATE POLICY "Users can read own cookbook" ON user_cookbook_recipes
  FOR SELECT USING (auth.uid() = user_id);

-- Only the owning user can add favorites; recipe must not be soft-deleted
CREATE POLICY "Users can add to own cookbook" ON user_cookbook_recipes
  FOR INSERT WITH CHECK (
    auth.uid() = user_id AND
    EXISTS (
      SELECT 1 FROM recipes r
      WHERE r.id = user_cookbook_recipes.recipe_id
        AND r.is_deleted = FALSE
    )
  );

-- Only the owning user can remove favorites
CREATE POLICY "Users can remove from own cookbook" ON user_cookbook_recipes
  FOR DELETE USING (auth.uid() = user_id);