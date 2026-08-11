-- Add media metadata columns to messages table
ALTER TABLE messages
ADD COLUMN IF NOT EXISTS storage_path TEXT,
ADD COLUMN IF NOT EXISTS file_name TEXT,
ADD COLUMN IF NOT EXISTS file_size BIGINT,
ADD COLUMN IF NOT EXISTS mime_type TEXT,
ADD COLUMN IF NOT EXISTS metadata JSONB;

-- Note: Supabase Storage bucket 'chat-media' must be created manually in the Dashboard.
-- After creating, run these policies in the SQL Editor:

/*
-- Policy for inserting files (must be a member of the conversation)
CREATE POLICY "Users can upload media to their conversations"
ON storage.objects FOR INSERT
TO authenticated
WITH CHECK (
  bucket_id = 'chat-media' AND
  (regexp_split_to_array(name, '/'))[1]::uuid IN (
    SELECT conversation_id FROM conversation_members WHERE user_id = auth.uid()
  )
);

-- Policy for selecting files (must be a member of the conversation)
CREATE POLICY "Users can view media from their conversations"
ON storage.objects FOR SELECT
TO authenticated
USING (
  bucket_id = 'chat-media' AND
  (regexp_split_to_array(name, '/'))[1]::uuid IN (
    SELECT conversation_id FROM conversation_members WHERE user_id = auth.uid()
  )
);
*/

-- Update the RPC to include these new fields
CREATE OR REPLACE FUNCTION get_user_conversations_v4()
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
