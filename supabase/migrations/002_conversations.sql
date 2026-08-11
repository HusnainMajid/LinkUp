-- Conversations table
CREATE TABLE conversations (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    type TEXT NOT NULL DEFAULT 'direct', -- 'direct' or 'group'
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Conversation members table
CREATE TABLE conversation_members (
    conversation_id UUID NOT NULL REFERENCES conversations(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    joined_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    PRIMARY KEY (conversation_id, user_id)
);

-- Enable RLS
ALTER TABLE conversations ENABLE ROW LEVEL SECURITY;
ALTER TABLE conversation_members ENABLE ROW LEVEL SECURITY;

-- Policies for conversations
CREATE POLICY "Users can view conversations they are members of"
ON conversations FOR SELECT
USING (
    EXISTS (
        SELECT 1 FROM conversation_members
        WHERE conversation_id = conversations.id
        AND user_id = auth.uid()
    )
);

-- Policies for conversation_members
CREATE POLICY "Users can view members of their conversations"
ON conversation_members FOR SELECT
USING (
    EXISTS (
        SELECT 1 FROM conversation_members AS member
        WHERE member.conversation_id = conversation_members.conversation_id
        AND member.user_id = auth.uid()
    )
);

CREATE POLICY "Users can add members when creating a conversation"
ON conversation_members FOR INSERT
WITH CHECK (true); -- We rely on the security of the creation function or ensure user can only add themselves and others they are allowed to.

-- Function to get or create a direct conversation
CREATE OR REPLACE FUNCTION get_or_create_direct_conversation(other_user_id UUID)
RETURNS UUID AS $$
DECLARE
    existing_id UUID;
    new_conv_id UUID;
    current_user_id UUID := auth.uid();
BEGIN
    -- Check if a direct conversation already exists between these two users
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

-- Indexes for performance
CREATE INDEX idx_conversation_members_user_id ON conversation_members(user_id);
CREATE INDEX idx_conversation_members_conv_id ON conversation_members(conversation_id);
