-- =====================================================
-- ADD ANALYTICS EVENTS (PAGE/CONTENT VIEWS & CLICKS)
-- =====================================================
-- Tracks page views and content interactions (e.g., recipe views, blog reads)
-- Insertable by any user (including anonymous), readable only by admins.
-- Entries are immutable (no updates or deletes allowed).
-- 
-- Author: Grocery App Team
-- Date: 2024-01-12
-- =====================================================

-- Table to record analytics events
CREATE TABLE IF NOT EXISTS analytics_events (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  -- When the event occurred (client/server timestamp). Defaults to now()
  occurred_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
  created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),

  -- Actor context
  user_id UUID REFERENCES auth.users(id) ON DELETE SET NULL,
  anonymous_id TEXT,           -- client-generated stable id (cookie/local storage)
  session_id TEXT,             -- client session identifier if available

  -- Event description
  event_name TEXT NOT NULL,    -- e.g., 'page_view', 'recipe_view', 'blog_post_view'
  content_type TEXT,           -- e.g., 'recipe', 'blog_post', 'page'
  content_id UUID,             -- optional related id (no FK to allow polymorphism)

  -- Page context
  page_url TEXT,
  page_path TEXT,
  referrer TEXT,
  user_agent TEXT,
  ip INET,

  -- Arbitrary additional attributes for future-proofing
  metadata JSONB NOT NULL DEFAULT '{}'::jsonb
);

-- Enable Row Level Security
ALTER TABLE analytics_events ENABLE ROW LEVEL SECURITY;

-- =====================================================
-- INDEXES
-- =====================================================
CREATE INDEX IF NOT EXISTS idx_analytics_events_occurred_at ON analytics_events(occurred_at);
CREATE INDEX IF NOT EXISTS idx_analytics_events_event_name ON analytics_events(event_name);
CREATE INDEX IF NOT EXISTS idx_analytics_events_content ON analytics_events(content_type, content_id);
CREATE INDEX IF NOT EXISTS idx_analytics_events_user ON analytics_events(user_id, anonymous_id);
CREATE INDEX IF NOT EXISTS idx_analytics_events_metadata_gin ON analytics_events USING gin(metadata);

-- =====================================================
-- IMMUTABILITY: BLOCK UPDATES/DELETES
-- =====================================================
CREATE OR REPLACE FUNCTION forbid_update_delete_on_analytics_events()
RETURNS TRIGGER AS $$
BEGIN
  RAISE EXCEPTION 'Updates and deletes are not allowed on analytics_events';
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER analytics_events_no_update
BEFORE UPDATE ON analytics_events
FOR EACH ROW EXECUTE FUNCTION forbid_update_delete_on_analytics_events();

CREATE TRIGGER analytics_events_no_delete
BEFORE DELETE ON analytics_events
FOR EACH ROW EXECUTE FUNCTION forbid_update_delete_on_analytics_events();

-- =====================================================
-- RLS POLICIES
-- =====================================================

-- Anyone (including anonymous) can insert analytics events
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies 
    WHERE schemaname = 'public' AND tablename = 'analytics_events' AND policyname = 'Anyone can insert analytics_events'
  ) THEN
    EXECUTE 'CREATE POLICY "Anyone can insert analytics_events" ON public.analytics_events FOR INSERT WITH CHECK (true)';
  END IF;
END$$;

-- Only admins can read analytics events
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies 
    WHERE schemaname = 'public' AND tablename = 'analytics_events' AND policyname = 'Only admins can select analytics_events'
  ) THEN
    EXECUTE 'CREATE POLICY "Only admins can select analytics_events" ON public.analytics_events FOR SELECT USING (current_user_is_admin())';
  END IF;
END$$;

-- Note: No UPDATE or DELETE policies are defined. With RLS enabled and the triggers above,
-- nobody (including admins) can modify or delete rows.

-- =====================================================
-- MIGRATION COMPLETE
-- =====================================================
-- ✅ Any user (including anon) can write analytics events
-- ✅ Only admins can read analytics events
-- ✅ Events are immutable (no updates or deletes)


