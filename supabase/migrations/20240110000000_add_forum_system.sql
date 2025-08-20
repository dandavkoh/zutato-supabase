-- =====================================================
-- ADD FORUM SYSTEM (SECTIONS, THREADS, POSTS, FOLLOWS, READS, MESSAGES)
-- =====================================================
-- Admins manage sections. Users create threads and posts. Everyone can read.
-- Threads and posts support soft delete (is_deleted), closing, and archiving.
-- Users can follow threads and receive inbox messages for new posts.
-- Users have a private inbox (user_messages) for messages and notifications.
-- Read-tracking per user/thread indicates what is read vs. unread.
--
-- Author: Grocery App Team
-- Date: 2024-01-10
-- =====================================================

CREATE EXTENSION IF NOT EXISTS pg_trgm;

-- =====================================================
-- HELPERS
-- =====================================================

-- Check if current user is admin (redeclared for idempotency)
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
-- SECTIONS
-- =====================================================

CREATE TABLE forum_sections (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  slug TEXT NOT NULL UNIQUE,
  title TEXT NOT NULL,
  description TEXT,
  sort_order INTEGER NOT NULL DEFAULT 0,
  is_archived BOOLEAN NOT NULL DEFAULT FALSE,
  created_by UUID REFERENCES auth.users(id) ON DELETE SET NULL,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

ALTER TABLE forum_sections ENABLE ROW LEVEL SECURITY;

-- Indexes
CREATE INDEX idx_forum_sections_sort_order ON forum_sections(sort_order);
CREATE INDEX idx_forum_sections_is_archived ON forum_sections(is_archived);

-- Triggers
CREATE TRIGGER update_forum_sections_updated_at BEFORE UPDATE ON forum_sections
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- RLS
CREATE POLICY "Everyone can read forum_sections" ON forum_sections
  FOR SELECT USING (true);

CREATE POLICY "Admins can insert forum_sections" ON forum_sections
  FOR INSERT WITH CHECK (current_user_is_admin());

CREATE POLICY "Admins can update forum_sections" ON forum_sections
  FOR UPDATE USING (current_user_is_admin())
  WITH CHECK (current_user_is_admin());

CREATE POLICY "Admins can delete forum_sections" ON forum_sections
  FOR DELETE USING (current_user_is_admin());

-- =====================================================
-- THREADS
-- =====================================================

CREATE TABLE forum_threads (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  section_id UUID REFERENCES forum_sections(id) ON DELETE CASCADE NOT NULL,
  title TEXT NOT NULL,
  body TEXT,
  created_by UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
  is_deleted BOOLEAN NOT NULL DEFAULT FALSE,
  deleted_at TIMESTAMP WITH TIME ZONE,
  deleted_by UUID REFERENCES auth.users(id),
  is_closed BOOLEAN NOT NULL DEFAULT FALSE,
  is_archived BOOLEAN NOT NULL DEFAULT FALSE,
  posts_count INTEGER NOT NULL DEFAULT 0,
  views_count INTEGER NOT NULL DEFAULT 0,
  last_posted_at TIMESTAMP WITH TIME ZONE,
  fts tsvector GENERATED ALWAYS AS (to_tsvector('german', coalesce(title, '') || ' ' || coalesce(body, ''))) STORED,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

ALTER TABLE forum_threads ENABLE ROW LEVEL SECURITY;

-- Indexes
CREATE INDEX idx_forum_threads_section_id ON forum_threads(section_id);
CREATE INDEX idx_forum_threads_created_by ON forum_threads(created_by);
CREATE INDEX idx_forum_threads_is_deleted ON forum_threads(is_deleted);
CREATE INDEX idx_forum_threads_is_closed ON forum_threads(is_closed);
CREATE INDEX idx_forum_threads_is_archived ON forum_threads(is_archived);
CREATE INDEX idx_forum_threads_last_posted_at ON forum_threads(last_posted_at);
CREATE INDEX idx_forum_threads_fts ON forum_threads USING gin(fts);
CREATE INDEX idx_forum_threads_title_trgm ON forum_threads USING gin(title gin_trgm_ops);

-- Triggers
CREATE TRIGGER update_forum_threads_updated_at BEFORE UPDATE ON forum_threads
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- RLS
-- Public can read visible threads
CREATE POLICY "Everyone can read forum_threads" ON forum_threads
  FOR SELECT USING (is_deleted = FALSE);

-- Admins can read all
CREATE POLICY "Admins can read all forum_threads" ON forum_threads
  FOR SELECT USING (current_user_is_admin());

-- Authenticated users can create threads in non-archived sections
CREATE POLICY "Authenticated users can create forum_threads" ON forum_threads
  FOR INSERT WITH CHECK (
    auth.uid() = created_by AND
    EXISTS (
      SELECT 1 FROM forum_sections s
      WHERE s.id = forum_threads.section_id
        AND s.is_archived = FALSE
    )
  );

-- Owners can update own threads (soft delete, edit); admins can update any
CREATE POLICY "Thread owners can update own forum_threads" ON forum_threads
  FOR UPDATE USING (auth.uid() = created_by)
  WITH CHECK (auth.uid() = created_by);

CREATE POLICY "Admins can update forum_threads" ON forum_threads
  FOR UPDATE USING (current_user_is_admin())
  WITH CHECK (current_user_is_admin());

-- No hard delete policy -> disallow DELETE

-- =====================================================
-- POSTS
-- =====================================================

CREATE TABLE forum_posts (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  thread_id UUID REFERENCES forum_threads(id) ON DELETE CASCADE NOT NULL,
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
  content TEXT NOT NULL,
  parent_post_id UUID REFERENCES forum_posts(id) ON DELETE CASCADE,
  is_deleted BOOLEAN NOT NULL DEFAULT FALSE,
  deleted_at TIMESTAMP WITH TIME ZONE,
  deleted_by UUID REFERENCES auth.users(id),
  fts tsvector GENERATED ALWAYS AS (to_tsvector('german', coalesce(content, ''))) STORED,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

ALTER TABLE forum_posts ENABLE ROW LEVEL SECURITY;

-- Indexes
CREATE INDEX idx_forum_posts_thread_id ON forum_posts(thread_id);
CREATE INDEX idx_forum_posts_user_id ON forum_posts(user_id);
CREATE INDEX idx_forum_posts_is_deleted ON forum_posts(is_deleted);
CREATE INDEX idx_forum_posts_created_at ON forum_posts(created_at);
CREATE INDEX idx_forum_posts_parent_post_id ON forum_posts(parent_post_id);
CREATE INDEX idx_forum_posts_fts ON forum_posts USING gin(fts);

-- Triggers
CREATE TRIGGER update_forum_posts_updated_at BEFORE UPDATE ON forum_posts
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- Maintain posts_count and last_posted_at on threads
CREATE OR REPLACE FUNCTION forum_posts_after_insert_update_thread_stats()
RETURNS TRIGGER AS $$
BEGIN
  UPDATE forum_threads
  SET posts_count = posts_count + 1,
      last_posted_at = NOW()
  WHERE id = NEW.thread_id;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER forum_posts_after_insert
AFTER INSERT ON forum_posts
FOR EACH ROW EXECUTE FUNCTION forum_posts_after_insert_update_thread_stats();

-- =====================================================
-- VOTES: forum_threads and forum_posts
-- =====================================================

-- Upvotes for threads
CREATE TABLE forum_thread_votes (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  thread_id UUID REFERENCES forum_threads(id) ON DELETE CASCADE NOT NULL,
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  UNIQUE(thread_id, user_id)
);

ALTER TABLE forum_thread_votes ENABLE ROW LEVEL SECURITY;

CREATE INDEX idx_forum_thread_votes_thread_id ON forum_thread_votes(thread_id);
CREATE INDEX idx_forum_thread_votes_user_id ON forum_thread_votes(user_id);
CREATE INDEX idx_forum_thread_votes_created_at ON forum_thread_votes(created_at);

CREATE TRIGGER update_forum_thread_votes_updated_at BEFORE UPDATE ON forum_thread_votes
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE POLICY "Everyone can read forum_thread_votes" ON forum_thread_votes
  FOR SELECT USING (true);

CREATE POLICY "Authenticated users can create forum_thread_votes" ON forum_thread_votes
  FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own forum_thread_votes" ON forum_thread_votes
  FOR UPDATE USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can delete own forum_thread_votes" ON forum_thread_votes
  FOR DELETE USING (auth.uid() = user_id);

-- Upvotes for posts
CREATE TABLE forum_post_votes (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  post_id UUID REFERENCES forum_posts(id) ON DELETE CASCADE NOT NULL,
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  UNIQUE(post_id, user_id)
);

ALTER TABLE forum_post_votes ENABLE ROW LEVEL SECURITY;

CREATE INDEX idx_forum_post_votes_post_id ON forum_post_votes(post_id);
CREATE INDEX idx_forum_post_votes_user_id ON forum_post_votes(user_id);
CREATE INDEX idx_forum_post_votes_created_at ON forum_post_votes(created_at);

CREATE TRIGGER update_forum_post_votes_updated_at BEFORE UPDATE ON forum_post_votes
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE POLICY "Everyone can read forum_post_votes" ON forum_post_votes
  FOR SELECT USING (true);

CREATE POLICY "Authenticated users can create forum_post_votes" ON forum_post_votes
  FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own forum_post_votes" ON forum_post_votes
  FOR UPDATE USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can delete own forum_post_votes" ON forum_post_votes
  FOR DELETE USING (auth.uid() = user_id);

-- RLS
-- Public can read visible posts in visible threads
CREATE POLICY "Everyone can read forum_posts" ON forum_posts
  FOR SELECT USING (
    is_deleted = FALSE AND
    EXISTS (
      SELECT 1 FROM forum_threads t
      WHERE t.id = forum_posts.thread_id
        AND t.is_deleted = FALSE
    )
  );

-- Admins can read all posts
CREATE POLICY "Admins can read all forum_posts" ON forum_posts
  FOR SELECT USING (current_user_is_admin());

-- Authenticated users can create posts only in open, non-archived, visible threads
CREATE POLICY "Authenticated users can create forum_posts" ON forum_posts
  FOR INSERT WITH CHECK (
    auth.uid() = user_id AND
    EXISTS (
      SELECT 1 FROM forum_threads t
      WHERE t.id = forum_posts.thread_id
        AND t.is_deleted = FALSE
        AND t.is_archived = FALSE
        AND t.is_closed = FALSE
    )
  );

-- Admins can always create posts
CREATE POLICY "Admins can create forum_posts" ON forum_posts
  FOR INSERT WITH CHECK (current_user_is_admin());

-- Users can update own posts; Admins can update any
CREATE POLICY "Users can update own forum_posts" ON forum_posts
  FOR UPDATE USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Admins can update forum_posts" ON forum_posts
  FOR UPDATE USING (current_user_is_admin())
  WITH CHECK (current_user_is_admin());

-- No hard delete (no DELETE policy)

-- =====================================================
-- THREAD FOLLOWS
-- =====================================================

CREATE TABLE forum_thread_follows (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  thread_id UUID REFERENCES forum_threads(id) ON DELETE CASCADE NOT NULL,
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  UNIQUE(thread_id, user_id)
);

ALTER TABLE forum_thread_follows ENABLE ROW LEVEL SECURITY;

CREATE INDEX idx_forum_thread_follows_thread_id ON forum_thread_follows(thread_id);
CREATE INDEX idx_forum_thread_follows_user_id ON forum_thread_follows(user_id);

-- RLS: users manage own follows; admins can read all
CREATE POLICY "Users can read own forum_thread_follows" ON forum_thread_follows
  FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Admins can read all forum_thread_follows" ON forum_thread_follows
  FOR SELECT USING (current_user_is_admin());

CREATE POLICY "Users can follow threads" ON forum_thread_follows
  FOR INSERT WITH CHECK (
    auth.uid() = user_id AND
    EXISTS (
      SELECT 1 FROM forum_threads t
      WHERE t.id = forum_thread_follows.thread_id
        AND t.is_deleted = FALSE
    )
  );

CREATE POLICY "Users can unfollow threads" ON forum_thread_follows
  FOR DELETE USING (auth.uid() = user_id);

-- =====================================================
-- THREAD READ TRACKING
-- =====================================================

CREATE TABLE forum_thread_reads (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  thread_id UUID REFERENCES forum_threads(id) ON DELETE CASCADE NOT NULL,
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
  last_read_post_id UUID REFERENCES forum_posts(id) ON DELETE SET NULL,
  last_read_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  UNIQUE(thread_id, user_id)
);

ALTER TABLE forum_thread_reads ENABLE ROW LEVEL SECURITY;

CREATE INDEX idx_forum_thread_reads_thread_id ON forum_thread_reads(thread_id);
CREATE INDEX idx_forum_thread_reads_user_id ON forum_thread_reads(user_id);

CREATE TRIGGER update_forum_thread_reads_updated_at BEFORE UPDATE ON forum_thread_reads
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- RLS: users can read/update only their records
CREATE POLICY "Users can read own forum_thread_reads" ON forum_thread_reads
  FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can upsert own forum_thread_reads" ON forum_thread_reads
  FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own forum_thread_reads" ON forum_thread_reads
  FOR UPDATE USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

-- =====================================================
-- USER MESSAGES (INBOX)
-- =====================================================

CREATE TABLE user_messages (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  sender_id UUID REFERENCES auth.users(id),
  recipient_id UUID REFERENCES auth.users(id) NOT NULL,
  subject TEXT NOT NULL,
  body TEXT NOT NULL,
  thread_id UUID REFERENCES forum_threads(id), -- optional link to thread (notifications)
  read_at TIMESTAMP WITH TIME ZONE,
  sender_deleted BOOLEAN NOT NULL DEFAULT FALSE,
  recipient_deleted BOOLEAN NOT NULL DEFAULT FALSE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

ALTER TABLE user_messages ENABLE ROW LEVEL SECURITY;

CREATE INDEX idx_user_messages_sender_id ON user_messages(sender_id);
CREATE INDEX idx_user_messages_recipient_id ON user_messages(recipient_id);
CREATE INDEX idx_user_messages_created_at ON user_messages(created_at);
CREATE INDEX idx_user_messages_thread_id ON user_messages(thread_id);

CREATE TRIGGER update_user_messages_updated_at BEFORE UPDATE ON user_messages
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- Prevent content edits; allow only read/deleted flags to change
CREATE OR REPLACE FUNCTION user_messages_restrict_updates()
RETURNS TRIGGER AS $$
BEGIN
  IF NEW.subject IS DISTINCT FROM OLD.subject OR
     NEW.body IS DISTINCT FROM OLD.body OR
     NEW.sender_id IS DISTINCT FROM OLD.sender_id OR
     NEW.recipient_id IS DISTINCT FROM OLD.recipient_id OR
     NEW.thread_id IS DISTINCT FROM OLD.thread_id THEN
    RAISE EXCEPTION 'Modifying message content or participants is not allowed';
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER user_messages_before_update
BEFORE UPDATE ON user_messages
FOR EACH ROW EXECUTE FUNCTION user_messages_restrict_updates();

-- RLS: participants only
CREATE POLICY "Participants can read user_messages" ON user_messages
  FOR SELECT USING (
    (auth.uid() = sender_id AND sender_deleted = FALSE) OR
    (auth.uid() = recipient_id AND recipient_deleted = FALSE)
  );

CREATE POLICY "Users can send user_messages" ON user_messages
  FOR INSERT WITH CHECK (
    (sender_id IS NULL OR auth.uid() = sender_id) AND recipient_id IS NOT NULL
  );

CREATE POLICY "Participants can update flags on user_messages" ON user_messages
  FOR UPDATE USING (auth.uid() IN (sender_id, recipient_id))
  WITH CHECK (auth.uid() IN (sender_id, recipient_id));

-- No DELETE policy (soft-delete via flags)

-- =====================================================
-- NOTIFICATIONS FOR FOLLOWERS ON NEW POSTS
-- =====================================================

CREATE OR REPLACE FUNCTION notify_thread_followers_on_new_post()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO user_messages (sender_id, recipient_id, subject, body, thread_id)
  SELECT NEW.user_id, f.user_id,
         'Neuer Beitrag im Thread',
         'Im Thread, dem du folgst, gibt es einen neuen Beitrag: ' || coalesce((SELECT title FROM forum_threads WHERE id = NEW.thread_id), ''),
         NEW.thread_id
  FROM forum_thread_follows f
  WHERE f.thread_id = NEW.thread_id
    AND f.user_id <> NEW.user_id;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER forum_posts_notify_followers
AFTER INSERT ON forum_posts
FOR EACH ROW EXECUTE FUNCTION notify_thread_followers_on_new_post();

-- =====================================================
-- MIGRATION COMPLETE
-- =====================================================
-- ✅ Sections with admin management
-- ✅ Threads with soft-delete, close, archive, counts, search
-- ✅ Posts with soft-delete and search
-- ✅ Thread follows and automatic inbox notifications
-- ✅ Per-user read tracking
-- ✅ User messages (inbox) with RLS for participants
-- ✅ RLS throughout to ensure proper access control

