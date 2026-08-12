-- Add group specific columns to conversations table
ALTER TABLE conversations
ADD COLUMN IF NOT EXISTS name TEXT,
ADD COLUMN IF NOT EXISTS avatar_url TEXT,
ADD COLUMN IF NOT EXISTS created_by UUID REFERENCES auth.users(id);

-- Add role column to conversation_members
ALTER TABLE conversation_members
ADD COLUMN IF NOT EXISTS role TEXT DEFAULT 'MEMBER' CHECK (role IN ('OWNER', 'ADMIN', 'MEMBER'));

-- Update existing direct conversations to have null name/avatar and MEMBER role
-- (Actually the defaults already handle this)

-- Function to create a group atomically
CREATE OR REPLACE FUNCTION create_group(
    group_name TEXT,
    group_avatar_url TEXT,
    member_ids UUID[]
)
RETURNS UUID AS $$
DECLARE
    new_conv_id UUID;
    member_id UUID;
    current_user_id UUID := auth.uid();
BEGIN
    -- Create new conversation
    INSERT INTO conversations (type, name, avatar_url, created_by)
    VALUES ('group', group_name, group_avatar_url, current_user_id)
    RETURNING id INTO new_conv_id;

    -- Add creator as OWNER
    INSERT INTO conversation_members (conversation_id, user_id, role)
    VALUES (new_conv_id, current_user_id, 'OWNER');

    -- Add other members as MEMBER
    FOREACH member_id IN ARRAY member_ids
    LOOP
        IF member_id <> current_user_id THEN
            INSERT INTO conversation_members (conversation_id, user_id, role)
            VALUES (new_conv_id, member_id, 'MEMBER');
        END IF;
    END LOOP;

    RETURN new_conv_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Update get_user_conversations to version 6 (including group info)
CREATE OR REPLACE FUNCTION get_user_conversations_v6()
RETURNS JSONB AS $$
DECLARE
    result JSONB;
BEGIN
    SELECT jsonb_agg(conv_data) INTO result
    FROM (
        SELECT
            c.id,
            c.type,
            c.name as group_name,
            c.avatar_url as group_avatar_url,
            c.created_at,
            c.updated_at,
            (
                SELECT jsonb_agg(jsonb_build_object('profile', p.*, 'role', cm.role))
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
                    'sender_name', (SELECT full_name FROM profiles WHERE id = m.sender_id),
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

-- Policies for group management
CREATE POLICY "Owners and admins can update group info"
ON conversations FOR UPDATE
TO authenticated
USING (
    EXISTS (
        SELECT 1 FROM conversation_members
        WHERE conversation_id = id
        AND user_id = auth.uid()
        AND role IN ('OWNER', 'ADMIN')
    )
);

CREATE POLICY "Owners can add/remove members"
ON conversation_members FOR ALL
TO authenticated
USING (
    EXISTS (
        SELECT 1 FROM conversation_members
        WHERE conversation_id = conversation_members.conversation_id
        AND user_id = auth.uid()
        AND role IN ('OWNER', 'ADMIN')
    )
)
WITH CHECK (
    EXISTS (
        SELECT 1 FROM conversation_members
        WHERE conversation_id = conversation_members.conversation_id
        AND user_id = auth.uid()
        AND role IN ('OWNER', 'ADMIN')
    )
);

-- Allow users to leave group
CREATE POLICY "Users can remove themselves from a group"
ON conversation_members FOR DELETE
TO authenticated
USING (user_id = auth.uid());
