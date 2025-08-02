-- =====================================================
-- ADD LIST INVITATIONS SYSTEM
-- =====================================================
-- 
-- This migration adds a list invitation system that allows
-- list owners to invite users via invitation codes.
--
-- Features:
-- - One-time use invitation codes
-- - 7-day expiration
-- - Soft delete functionality
-- - Row Level Security protection
-- - Owner can invalidate codes
-- - Users can redeem codes to become list members
--
-- Author: Grocery App Team
-- Date: 2024-01-03
-- =====================================================

-- =====================================================
-- LIST_INVITATIONS TABLE
-- =====================================================
-- Stores invitation codes for list access
-- Each code is unique, expires after 7 days, and can only be used once

CREATE TABLE list_invitations (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  list_id UUID REFERENCES lists(id) ON DELETE CASCADE NOT NULL,
  invitation_code TEXT NOT NULL UNIQUE,
  created_by UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  expires_at TIMESTAMP WITH TIME ZONE NOT NULL,
  used_by UUID REFERENCES auth.users(id),
  used_at TIMESTAMP WITH TIME ZONE,
  is_deleted BOOLEAN DEFAULT FALSE,
  deleted_at TIMESTAMP WITH TIME ZONE,
  deleted_by UUID REFERENCES auth.users(id),
  is_invalidated BOOLEAN DEFAULT FALSE,
  invalidated_at TIMESTAMP WITH TIME ZONE,
  invalidated_by UUID REFERENCES auth.users(id)
);

-- Enable Row Level Security for data protection
ALTER TABLE list_invitations ENABLE ROW LEVEL SECURITY;

-- =====================================================
-- INDEXES FOR PERFORMANCE OPTIMIZATION
-- =====================================================

-- List invitations indexes
CREATE INDEX idx_list_invitations_list_id ON list_invitations(list_id);
CREATE INDEX idx_list_invitations_invitation_code ON list_invitations(invitation_code);
CREATE INDEX idx_list_invitations_created_by ON list_invitations(created_by);
CREATE INDEX idx_list_invitations_expires_at ON list_invitations(expires_at);
CREATE INDEX idx_list_invitations_is_deleted ON list_invitations(is_deleted);
CREATE INDEX idx_list_invitations_is_invalidated ON list_invitations(is_invalidated);
CREATE INDEX idx_list_invitations_used_by ON list_invitations(used_by);

-- =====================================================
-- HELPER FUNCTIONS - Invitation management
-- =====================================================

-- Generate a unique invitation code
CREATE OR REPLACE FUNCTION generate_invitation_code()
RETURNS TEXT AS $$
DECLARE
  code TEXT;
  counter INTEGER := 0;
BEGIN
  LOOP
    -- Generate a 12-character alphanumeric code
    code := upper(substring(md5(random()::text || clock_timestamp()::text) from 1 for 12));
    
    -- Check if code already exists
    IF NOT EXISTS (SELECT 1 FROM list_invitations WHERE invitation_code = code) THEN
      RETURN code;
    END IF;
    
    counter := counter + 1;
    -- Prevent infinite loop
    IF counter > 100 THEN
      RAISE EXCEPTION 'Could not generate unique invitation code after 100 attempts';
    END IF;
  END LOOP;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Check if an invitation code is valid (not expired, not used, not deleted, not invalidated)
CREATE OR REPLACE FUNCTION is_invitation_valid(code TEXT)
RETURNS BOOLEAN AS $$
BEGIN
  RETURN EXISTS (
    SELECT 1 FROM list_invitations 
    WHERE invitation_code = code
    AND expires_at > NOW()
    AND used_by IS NULL
    AND is_deleted = FALSE
    AND is_invalidated = FALSE
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Get invitation details by code
CREATE OR REPLACE FUNCTION get_invitation_by_code(code TEXT)
RETURNS TABLE (
  id UUID,
  list_id UUID,
  invitation_code TEXT,
  created_by UUID,
  created_at TIMESTAMP WITH TIME ZONE,
  expires_at TIMESTAMP WITH TIME ZONE,
  used_by UUID,
  used_at TIMESTAMP WITH TIME ZONE,
  is_deleted BOOLEAN,
  is_invalidated BOOLEAN
) AS $$
BEGIN
  RETURN QUERY
  SELECT 
    li.id,
    li.list_id,
    li.invitation_code,
    li.created_by,
    li.created_at,
    li.expires_at,
    li.used_by,
    li.used_at,
    li.is_deleted,
    li.is_invalidated
  FROM list_invitations li
  WHERE li.invitation_code = code;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- =====================================================
-- ROW LEVEL SECURITY (RLS) POLICIES
-- =====================================================

-- List owners can view their own invitations
CREATE POLICY "List owners can view their invitations" ON list_invitations
  FOR SELECT USING (
    is_list_owner(list_invitations.list_id, auth.uid())
  );

-- List owners can create invitations for their lists
CREATE POLICY "List owners can create invitations" ON list_invitations
  FOR INSERT WITH CHECK (
    is_list_owner(list_invitations.list_id, auth.uid()) AND
    auth.uid() = created_by
  );

-- List owners can invalidate their own invitations
CREATE POLICY "List owners can invalidate invitations" ON list_invitations
  FOR UPDATE USING (
    is_list_owner(list_invitations.list_id, auth.uid())
  );

-- List owners can soft delete their own invitations
CREATE POLICY "List owners can delete invitations" ON list_invitations
  FOR DELETE USING (
    is_list_owner(list_invitations.list_id, auth.uid())
  );

-- Users can view invitations they have used
CREATE POLICY "Users can view invitations they used" ON list_invitations
  FOR SELECT USING (
    auth.uid() = used_by
  );

-- =====================================================
-- TRIGGERS - Automatic timestamp updates
-- =====================================================

-- Update updated_at timestamp on invitation changes (if we had an updated_at column)
-- For now, we'll rely on the existing timestamp columns

-- =====================================================
-- API FUNCTIONS - Public interface for invitation management
-- =====================================================

-- Create a new invitation for a list (called by list owner)
CREATE OR REPLACE FUNCTION create_list_invitation(list_uuid UUID)
RETURNS TABLE (
  invitation_code TEXT,
  expires_at TIMESTAMP WITH TIME ZONE,
  created_at TIMESTAMP WITH TIME ZONE
) AS $$
DECLARE
  new_code TEXT;
  expiration_time TIMESTAMP WITH TIME ZONE;
BEGIN
  -- Check if user is the list owner
  IF NOT is_list_owner(list_uuid, auth.uid()) THEN
    RAISE EXCEPTION 'Only list owners can create invitations';
  END IF;
  
  -- Generate unique invitation code
  new_code := generate_invitation_code();
  
  -- Set expiration to 7 days from now
  expiration_time := NOW() + INTERVAL '7 days';
  
  -- Insert the invitation
  INSERT INTO list_invitations (
    list_id,
    invitation_code,
    created_by,
    expires_at
  ) VALUES (
    list_uuid,
    new_code,
    auth.uid(),
    expiration_time
  );
  
  -- Return the invitation details
  RETURN QUERY
  SELECT 
    li.invitation_code,
    li.expires_at,
    li.created_at
  FROM list_invitations li
  WHERE li.invitation_code = new_code;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Redeem an invitation code (called by user)
CREATE OR REPLACE FUNCTION redeem_invitation_code(code TEXT)
RETURNS TABLE (
  success BOOLEAN,
  message TEXT,
  list_id UUID,
  list_name TEXT
) AS $$
DECLARE
  invitation_record RECORD;
  list_record RECORD;
BEGIN
  -- Check if invitation code is valid
  IF NOT is_invitation_valid(code) THEN
    RETURN QUERY SELECT FALSE, 'Invalid or expired invitation code', NULL::UUID, NULL::TEXT;
    RETURN;
  END IF;
  
  -- Get invitation details
  SELECT * INTO invitation_record FROM get_invitation_by_code(code);
  
  -- Check if user is already a member of the list
  IF is_list_member(invitation_record.list_id, auth.uid()) THEN
    RETURN QUERY SELECT FALSE, 'You are already a member of this list', NULL::UUID, NULL::TEXT;
    RETURN;
  END IF;
  
  -- Get list details
  SELECT * INTO list_record FROM lists WHERE id = invitation_record.list_id;
  
  -- Mark invitation as used
  UPDATE list_invitations 
  SET used_by = auth.uid(),
      used_at = NOW()
  WHERE invitation_code = code;
  
  -- Add user as member to the list
  INSERT INTO list_members (
    list_id,
    user_id,
    role,
    invited_by,
    accepted_at
  ) VALUES (
    invitation_record.list_id,
    auth.uid(),
    'editor',
    invitation_record.created_by,
    NOW()
  );
  
  -- Return success
  RETURN QUERY SELECT TRUE, 'Successfully joined the list', invitation_record.list_id, list_record.name;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Invalidate an invitation (called by list owner)
CREATE OR REPLACE FUNCTION invalidate_invitation(invitation_uuid UUID)
RETURNS TABLE (
  success BOOLEAN,
  message TEXT
) AS $$
DECLARE
  invitation_record RECORD;
BEGIN
  -- Get invitation details
  SELECT * INTO invitation_record FROM list_invitations WHERE id = invitation_uuid;
  
  -- Check if invitation exists
  IF invitation_record IS NULL THEN
    RETURN QUERY SELECT FALSE, 'Invitation not found';
    RETURN;
  END IF;
  
  -- Check if user is the list owner
  IF NOT is_list_owner(invitation_record.list_id, auth.uid()) THEN
    RETURN QUERY SELECT FALSE, 'Only list owners can invalidate invitations';
    RETURN;
  END IF;
  
  -- Check if invitation is already used
  IF invitation_record.used_by IS NOT NULL THEN
    RETURN QUERY SELECT FALSE, 'Cannot invalidate already used invitation';
    RETURN;
  END IF;
  
  -- Check if invitation is already invalidated
  IF invitation_record.is_invalidated THEN
    RETURN QUERY SELECT FALSE, 'Invitation is already invalidated';
    RETURN;
  END IF;
  
  -- Invalidate the invitation
  UPDATE list_invitations 
  SET is_invalidated = TRUE,
      invalidated_at = NOW(),
      invalidated_by = auth.uid()
  WHERE id = invitation_uuid;
  
  -- Return success
  RETURN QUERY SELECT TRUE, 'Invitation successfully invalidated';
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Soft delete an invitation (called by list owner)
CREATE OR REPLACE FUNCTION soft_delete_invitation(invitation_uuid UUID)
RETURNS TABLE (
  success BOOLEAN,
  message TEXT
) AS $$
DECLARE
  invitation_record RECORD;
BEGIN
  -- Get invitation details
  SELECT * INTO invitation_record FROM list_invitations WHERE id = invitation_uuid;
  
  -- Check if invitation exists
  IF invitation_record IS NULL THEN
    RETURN QUERY SELECT FALSE, 'Invitation not found';
    RETURN;
  END IF;
  
  -- Check if user is the list owner
  IF NOT is_list_owner(invitation_record.list_id, auth.uid()) THEN
    RETURN QUERY SELECT FALSE, 'Only list owners can delete invitations';
    RETURN;
  END IF;
  
  -- Check if invitation is already deleted
  IF invitation_record.is_deleted THEN
    RETURN QUERY SELECT FALSE, 'Invitation is already deleted';
    RETURN;
  END IF;
  
  -- Soft delete the invitation
  UPDATE list_invitations 
  SET is_deleted = TRUE,
      deleted_at = NOW(),
      deleted_by = auth.uid()
  WHERE id = invitation_uuid;
  
  -- Return success
  RETURN QUERY SELECT TRUE, 'Invitation successfully deleted';
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Get all invitations for a list (called by list owner)
CREATE OR REPLACE FUNCTION get_list_invitations(list_uuid UUID)
RETURNS TABLE (
  id UUID,
  invitation_code TEXT,
  created_at TIMESTAMP WITH TIME ZONE,
  expires_at TIMESTAMP WITH TIME ZONE,
  used_by UUID,
  used_at TIMESTAMP WITH TIME ZONE,
  is_invalidated BOOLEAN,
  invalidated_at TIMESTAMP WITH TIME ZONE,
  is_deleted BOOLEAN,
  status TEXT
) AS $$
BEGIN
  -- Check if user is the list owner
  IF NOT is_list_owner(list_uuid, auth.uid()) THEN
    RAISE EXCEPTION 'Only list owners can view invitations';
  END IF;
  
  -- Return invitations for the list
  RETURN QUERY
  SELECT 
    li.id,
    li.invitation_code,
    li.created_at,
    li.expires_at,
    li.used_by,
    li.used_at,
    li.is_invalidated,
    li.invalidated_at,
    li.is_deleted,
    CASE 
      WHEN li.is_deleted THEN 'deleted'
      WHEN li.is_invalidated THEN 'invalidated'
      WHEN li.used_by IS NOT NULL THEN 'used'
      WHEN li.expires_at <= NOW() THEN 'expired'
      ELSE 'active'
    END as status
  FROM list_invitations li
  WHERE li.list_id = list_uuid
  ORDER BY li.created_at DESC;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- =====================================================
-- CLEANUP FUNCTION - Remove expired invitations
-- =====================================================
-- This function can be called periodically to clean up expired invitations

CREATE OR REPLACE FUNCTION cleanup_expired_invitations()
RETURNS INTEGER AS $$
DECLARE
  deleted_count INTEGER;
BEGIN
  -- Soft delete expired invitations that haven't been used
  UPDATE list_invitations 
  SET is_deleted = TRUE,
      deleted_at = NOW(),
      deleted_by = NULL
  WHERE expires_at <= NOW()
    AND used_by IS NULL
    AND is_deleted = FALSE
    AND is_invalidated = FALSE;
  
  GET DIAGNOSTICS deleted_count = ROW_COUNT;
  
  RETURN deleted_count;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- =====================================================
-- VIEWS - Convenient data access
-- =====================================================

-- View showing active invitations with list details
CREATE VIEW active_invitations AS
SELECT 
  li.*,
  l.name as list_name,
  creator.email as creator_email,
  creator.raw_user_meta_data->>'full_name' as creator_name,
  used_user.email as used_user_email,
  used_user.raw_user_meta_data->>'full_name' as used_user_name
FROM list_invitations li
JOIN lists l ON li.list_id = l.id
JOIN auth.users creator ON li.created_by = creator.id
LEFT JOIN auth.users used_user ON li.used_by = used_user.id
WHERE li.is_deleted = FALSE;

-- =====================================================
-- MIGRATION COMPLETE
-- =====================================================
-- 
-- The invitation system is now ready with:
-- ✅ One-time use invitation codes
-- ✅ 7-day expiration
-- ✅ Soft delete functionality
-- ✅ Row Level Security protection
-- ✅ Owner can invalidate codes
-- ✅ Users can redeem codes to become list members
-- ✅ Helper functions for code generation and validation
-- ✅ API functions for frontend integration
-- ✅ Cleanup function for expired invitations
-- ✅ Convenient views for data access
--
-- Next steps:
-- 1. Test the invitation system
-- 2. Create frontend integration
-- 3. Set up periodic cleanup of expired invitations
-- ===================================================== 