-- Add UPDATE policy for conversations to allow members to update activity timestamp
CREATE POLICY "Users can update conversations they are members of"
ON conversations FOR UPDATE
USING (
    EXISTS (
        SELECT 1 FROM conversation_members
        WHERE conversation_id = conversations.id
        AND user_id = auth.uid()
    )
)
WITH CHECK (
    EXISTS (
        SELECT 1 FROM conversation_members
        WHERE conversation_id = conversations.id
        AND user_id = auth.uid()
    )
);

-- Trigger function to handle new message activity
-- This ensures conversations move to top and reappear if they were deleted
CREATE OR REPLACE FUNCTION handle_new_message_activity()
RETURNS TRIGGER AS $$
BEGIN
    -- Update conversation activity timestamp
    UPDATE conversations
    SET updated_at = now()
    WHERE id = NEW.conversation_id;

    -- Ensure preferences exist and are not 'deleted' for all members
    -- This makes the chat reappear for someone who might have 'deleted' it
    -- but then receives a new message.
    INSERT INTO user_conversation_preferences (user_id, conversation_id, is_deleted, updated_at)
    SELECT user_id, NEW.conversation_id, false, now()
    FROM conversation_members
    WHERE conversation_id = NEW.conversation_id
    ON CONFLICT (user_id, conversation_id) DO UPDATE
    SET is_deleted = false, updated_at = now();

    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Add trigger to messages table
DROP TRIGGER IF EXISTS on_message_inserted_activity ON messages;
CREATE TRIGGER on_message_inserted_activity
AFTER INSERT ON messages
FOR EACH ROW
EXECUTE FUNCTION handle_new_message_activity();

-- Optimize get_user_conversations_v4 to be more resilient
CREATE OR REPLACE FUNCTION get_user_conversations_v5()
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
                    'conversation_id', m.conversation_id,
                    'content', m.content,
                    'sender_id', m.sender_id,
                    'created_at', m.created_at,
                    'message_type', m.message_type,
                    'deleted_at', m.deleted_at,
                    'storage_path', m.storage_path,
                    'file_name', m.file_name
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
            ) as preferences,
            (
                SELECT count(*)::int
                FROM messages m
                LEFT JOIN user_conversation_preferences ucp ON ucp.conversation_id = c.id AND ucp.user_id = auth.uid()
                WHERE m.conversation_id = c.id
                  AND m.sender_id <> auth.uid()
                  AND (ucp.last_read_at IS NULL OR m.created_at > ucp.last_read_at)
            ) as unread_count
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
