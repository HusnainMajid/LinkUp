-- Fix recursion in conversation_members policies
-- We use a security definer function to check membership without triggering RLS recursively

CREATE OR REPLACE FUNCTION is_member_of_conversation(p_conversation_id UUID)
RETURNS BOOLEAN AS $$
BEGIN
    RETURN EXISTS (
        SELECT 1 FROM conversation_members
        WHERE conversation_id = p_conversation_id
        AND user_id = auth.uid()
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE OR REPLACE FUNCTION get_user_role_in_conversation(p_conversation_id UUID)
RETURNS TEXT AS $$
BEGIN
    RETURN (
        SELECT role FROM conversation_members
        WHERE conversation_id = p_conversation_id
        AND user_id = auth.uid()
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Drop old policies
DROP POLICY IF EXISTS "Users can view members of their conversations" ON conversation_members;
DROP POLICY IF EXISTS "Owners can add/remove members" ON conversation_members;
DROP POLICY IF EXISTS "Users can remove themselves from a group" ON conversation_members;
DROP POLICY IF EXISTS "Owners and admins can manage members" ON conversation_members;

-- Re-create policies using the non-recursive functions
CREATE POLICY "Users can view members of their conversations"
ON conversation_members FOR SELECT
TO authenticated
USING (is_member_of_conversation(conversation_id));

CREATE POLICY "Owners and admins can manage members"
ON conversation_members FOR ALL
TO authenticated
USING (get_user_role_in_conversation(conversation_id) IN ('OWNER', 'ADMIN'))
WITH CHECK (get_user_role_in_conversation(conversation_id) IN ('OWNER', 'ADMIN'));

CREATE POLICY "Users can always remove themselves"
ON conversation_members FOR DELETE
TO authenticated
USING (user_id = auth.uid());

-- Fix conversations policies
DROP POLICY IF EXISTS "Users can view conversations they are members of" ON conversations;
CREATE POLICY "Users can view conversations they are members of"
ON conversations FOR SELECT
TO authenticated
USING (is_member_of_conversation(id));

DROP POLICY IF EXISTS "Users can update conversations they are members of" ON conversations;
DROP POLICY IF EXISTS "Owners and admins can update group info" ON conversations;
DROP POLICY IF EXISTS "Users can update basic conversation info" ON conversations;

CREATE POLICY "Users can update basic conversation info"
ON conversations FOR UPDATE
TO authenticated
USING (is_member_of_conversation(id))
WITH CHECK (is_member_of_conversation(id));

-- Fix messages policy to avoid using SELECT conversation_members directly
DROP POLICY IF EXISTS "Users can insert messages in their conversations" ON messages;
CREATE POLICY "Users can insert messages in their conversations"
ON messages FOR INSERT
TO authenticated
WITH CHECK (
    sender_id = auth.uid() AND
    is_member_of_conversation(conversation_id)
);

DROP POLICY IF EXISTS "Users can select messages in their conversations" ON messages;
CREATE POLICY "Users can select messages in their conversations"
ON messages FOR SELECT
TO authenticated
USING (is_member_of_conversation(conversation_id));
