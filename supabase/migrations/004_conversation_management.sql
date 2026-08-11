-- User conversation preferences/state
CREATE TABLE user_conversation_preferences (
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    conversation_id UUID NOT NULL REFERENCES conversations(id) ON DELETE CASCADE,
    is_pinned BOOLEAN DEFAULT false,
    is_archived BOOLEAN DEFAULT false,
    is_muted BOOLEAN DEFAULT false,
    is_deleted BOOLEAN DEFAULT false,
    last_read_at TIMESTAMPTZ DEFAULT now(),
    created_at TIMESTAMPTZ DEFAULT now(),
    updated_at TIMESTAMPTZ DEFAULT now(),
    PRIMARY KEY (user_id, conversation_id)
);

-- Enable RLS
ALTER TABLE user_conversation_preferences ENABLE ROW LEVEL SECURITY;

-- Policies
CREATE POLICY "Users can manage their own preferences"
ON user_conversation_preferences FOR ALL
USING (user_id = auth.uid())
WITH CHECK (user_id = auth.uid());

-- Indexing for performance
CREATE INDEX idx_ucp_user_id ON user_conversation_preferences(user_id);
CREATE INDEX idx_ucp_conversation_id ON user_conversation_preferences(conversation_id);
CREATE INDEX idx_ucp_archived ON user_conversation_preferences(is_archived);
CREATE INDEX idx_ucp_pinned ON user_conversation_preferences(is_pinned);

-- Function to get conversations with latest message and preferences
CREATE OR REPLACE FUNCTION get_user_conversations_v3()
RETURNS JSONB AS $$
DECLARE
    result JSONB;
BEGIN
    SELECT jsonb_agg(conv_data) INTO result
    FROM (
        SELECT
            c.id,
            c.type,
            c.created_at,
            c.updated_at,
            (
                SELECT jsonb_agg(jsonb_build_object('profile', p.*))
                FROM conversation_members cm
                JOIN profiles p ON p.id = cm.user_id
                WHERE cm.conversation_id = c.id
            ) as members,
            (
                SELECT jsonb_build_object(
                    'id', m.id,
                    'content', m.content,
                    'sender_id', m.sender_id,
                    'created_at', m.created_at,
                    'message_type', m.message_type,
                    'deleted_at', m.deleted_at
                )
                FROM messages m
                WHERE m.conversation_id = c.id
                ORDER BY m.created_at DESC
                LIMIT 1
            ) as latest_message,
            (
                SELECT jsonb_build_object(
                    'is_pinned', COALESCE(ucp.is_pinned, false),
                    'is_archived', COALESCE(ucp.is_archived, false),
                    'is_muted', COALESCE(ucp.is_muted, false),
                    'is_deleted', COALESCE(ucp.is_deleted, false),
                    'last_read_at', ucp.last_read_at
                )
                FROM user_conversation_preferences ucp
                WHERE ucp.conversation_id = c.id AND ucp.user_id = auth.uid()
            ) as preferences
        FROM conversations c
        JOIN conversation_members cm_self ON cm_self.conversation_id = c.id
        WHERE cm_self.user_id = auth.uid()
        AND NOT EXISTS (
            SELECT 1 FROM user_conversation_preferences ucp
            WHERE ucp.conversation_id = c.id
            AND ucp.user_id = auth.uid()
            AND ucp.is_deleted = true
        )
        ORDER BY
            COALESCE((SELECT is_pinned FROM user_conversation_preferences ucp WHERE ucp.conversation_id = c.id AND ucp.user_id = auth.uid()), false) DESC,
            c.updated_at DESC
    ) conv_data;

    RETURN COALESCE(result, '[]'::jsonb);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Enable Realtime for preferences
ALTER PUBLICATION supabase_realtime ADD TABLE user_conversation_preferences;
