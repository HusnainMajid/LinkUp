-- Add advanced messaging columns to messages table
ALTER TABLE messages
ADD COLUMN IF NOT EXISTS edited_at TIMESTAMPTZ,
ADD COLUMN IF NOT EXISTS delivered_at TIMESTAMPTZ,
ADD COLUMN IF NOT EXISTS read_at TIMESTAMPTZ;

-- Add presence columns to profiles table
ALTER TABLE profiles
ADD COLUMN IF NOT EXISTS last_seen TIMESTAMPTZ DEFAULT now(),
ADD COLUMN IF NOT EXISTS is_online BOOLEAN DEFAULT false;

-- Create message_reactions table
CREATE TABLE IF NOT EXISTS message_reactions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    message_id UUID NOT NULL REFERENCES messages(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    reaction TEXT NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    UNIQUE(message_id, user_id)
);

-- Enable RLS for reactions
ALTER TABLE message_reactions ENABLE ROW LEVEL SECURITY;

-- Policies for message_reactions
CREATE POLICY "Users can view reactions in their conversations"
ON message_reactions FOR SELECT
TO authenticated
USING (
    EXISTS (
        SELECT 1 FROM messages m
        JOIN conversation_members cm ON cm.conversation_id = m.conversation_id
        WHERE m.id = message_reactions.message_id
        AND cm.user_id = auth.uid()
    )
);

CREATE POLICY "Users can add their own reactions"
ON message_reactions FOR INSERT
TO authenticated
WITH CHECK (
    user_id = auth.uid() AND
    EXISTS (
        SELECT 1 FROM messages m
        JOIN conversation_members cm ON cm.conversation_id = m.conversation_id
        WHERE m.id = message_id
        AND cm.user_id = auth.uid()
    )
);

CREATE POLICY "Users can remove their own reactions"
ON message_reactions FOR DELETE
TO authenticated
USING (user_id = auth.uid());

-- Function to mark messages as read
CREATE OR REPLACE FUNCTION mark_messages_as_read(conv_id UUID, user_id UUID)
RETURNS VOID AS $$
BEGIN
    UPDATE messages
    SET read_at = now()
    WHERE conversation_id = conv_id
      AND sender_id <> user_id
      AND read_at IS NULL;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Enable Realtime for reactions and profile presence
ALTER PUBLICATION supabase_realtime ADD TABLE message_reactions;
ALTER PUBLICATION supabase_realtime ADD TABLE profiles;

-- Add indexes
CREATE INDEX idx_message_reactions_message_id ON message_reactions(message_id);
CREATE INDEX idx_messages_read_at ON messages(read_at);
CREATE INDEX idx_profiles_is_online ON profiles(is_online);
