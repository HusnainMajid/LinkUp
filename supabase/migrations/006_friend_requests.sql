-- Friend Requests Table
CREATE TABLE friend_requests (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    sender_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
    receiver_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
    status TEXT NOT NULL CHECK (status IN ('pending', 'accepted', 'rejected', 'cancelled')),
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),

    -- Prevent duplicate active requests between same users
    -- We use a unique index to ensure only one "active" relation exists
    -- Status can be rejected or cancelled multiple times, but only one 'pending' or 'accepted' should exist
    CONSTRAINT no_self_request CHECK (sender_id <> receiver_id)
);

-- Unique index to prevent multiple pending/accepted requests between same users
CREATE UNIQUE INDEX idx_unique_active_request ON friend_requests (
    LEAST(sender_id, receiver_id),
    GREATEST(sender_id, receiver_id)
) WHERE status IN ('pending', 'accepted');

-- Enable RLS
ALTER TABLE friend_requests ENABLE ROW LEVEL SECURITY;

-- RLS Policies
CREATE POLICY "Users can view requests they are involved in"
ON friend_requests FOR SELECT
TO authenticated
USING (auth.uid() = sender_id OR auth.uid() = receiver_id);

CREATE POLICY "Users can send friend requests"
ON friend_requests FOR INSERT
TO authenticated
WITH CHECK (auth.uid() = sender_id);

CREATE POLICY "Users can update their involved requests"
ON friend_requests FOR UPDATE
TO authenticated
USING (auth.uid() = sender_id OR auth.uid() = receiver_id)
WITH CHECK (
    (auth.uid() = sender_id AND status = 'cancelled') OR -- Sender can cancel
    (auth.uid() = receiver_id AND status IN ('accepted', 'rejected')) -- Receiver can accept/reject
);

-- Friendship Helper Functions
CREATE OR REPLACE FUNCTION is_friends(user_a UUID, user_b UUID)
RETURNS BOOLEAN AS $$
BEGIN
    RETURN EXISTS (
        SELECT 1 FROM friend_requests
        WHERE status = 'accepted'
        AND (
            (sender_id = user_a AND receiver_id = user_b) OR
            (sender_id = user_b AND receiver_id = user_a)
        )
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE OR REPLACE FUNCTION get_friend_status(other_user_id UUID)
RETURNS TEXT AS $$
DECLARE
    req_status TEXT;
    is_sender BOOLEAN;
BEGIN
    SELECT status, (sender_id = auth.uid()) INTO req_status, is_sender
    FROM friend_requests
    WHERE (sender_id = auth.uid() AND receiver_id = other_user_id)
       OR (sender_id = other_user_id AND receiver_id = auth.uid())
    ORDER BY updated_at DESC
    LIMIT 1;

    IF req_status IS NULL THEN
        RETURN 'none';
    ELSIF req_status = 'accepted' THEN
        RETURN 'friends';
    ELSIF req_status = 'pending' THEN
        RETURN CASE WHEN is_sender THEN 'pending_sent' ELSE 'pending_received' END;
    ELSIF req_status = 'rejected' THEN
        RETURN 'rejected';
    ELSE
        RETURN 'none';
    END IF;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Enforce Friendship on Conversation Creation
CREATE OR REPLACE FUNCTION get_or_create_direct_conversation(other_user_id UUID)
RETURNS UUID AS $$
DECLARE
    existing_id UUID;
    new_conv_id UUID;
    current_user_id UUID := auth.uid();
BEGIN
    -- CRITICAL RULE: Must be friends
    IF NOT is_friends(current_user_id, other_user_id) THEN
        RAISE EXCEPTION 'Users must be friends before starting a conversation.';
    END IF;

    -- Check if a direct conversation already exists
    SELECT cm1.conversation_id INTO existing_id
    FROM conversation_members cm1
    JOIN conversation_members cm2 ON cm1.conversation_id = cm2.conversation_id
    JOIN conversations c ON c.id = cm1.conversation_id
    WHERE c.type = 'direct'
      AND cm1.user_id = current_user_id
      AND cm2.user_id = other_user_id;

    IF existing_id IS NOT NULL THEN
        RETURN existing_id;
    END IF;

    -- Create new conversation
    INSERT INTO conversations (type) VALUES ('direct') RETURNING id INTO new_conv_id;

    -- Add both members
    INSERT INTO conversation_members (conversation_id, user_id)
    VALUES (new_conv_id, current_user_id), (new_conv_id, other_user_id);

    RETURN new_conv_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- RLS for Messages to enforce friendship at runtime
-- Note: This is a preventative measure for existing conversations
DROP POLICY IF EXISTS "Users can insert messages in their conversations" ON messages;
CREATE POLICY "Users can insert messages in their conversations"
ON messages FOR INSERT
WITH CHECK (
    sender_id = auth.uid() AND
    EXISTS (
        SELECT 1 FROM conversation_members cm1
        JOIN conversation_members cm2 ON cm1.conversation_id = cm2.conversation_id
        WHERE cm1.conversation_id = messages.conversation_id
        AND cm1.user_id = auth.uid()
        AND is_friends(cm1.user_id, cm2.user_id)
    )
);

-- Enable Realtime for friend_requests
ALTER PUBLICATION supabase_realtime ADD TABLE friend_requests;

-- Indexes
CREATE INDEX idx_friend_requests_sender ON friend_requests(sender_id);
CREATE INDEX idx_friend_requests_receiver ON friend_requests(receiver_id);
CREATE INDEX idx_friend_requests_status ON friend_requests(status);
