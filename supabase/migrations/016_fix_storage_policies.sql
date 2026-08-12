-- Fix storage policies to handle non-UUID folder names and allow group avatars
-- This prevents the "invalid input syntax for type uuid" error

-- Drop old policies to replace them with safer versions
DROP POLICY IF EXISTS "Users can upload media to their conversations" ON storage.objects;
DROP POLICY IF EXISTS "Users can view media from their conversations" ON storage.objects;
DROP POLICY IF EXISTS "Safer media upload policy" ON storage.objects;
DROP POLICY IF EXISTS "Safer media view policy" ON storage.objects;

-- Helper function to check if a string is a valid UUID
CREATE OR REPLACE FUNCTION is_valid_uuid(text_to_check TEXT)
RETURNS BOOLEAN AS $$
BEGIN
    IF text_to_check IS NULL THEN RETURN FALSE; END IF;
    RETURN text_to_check ~ '^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$';
END;
$$ LANGUAGE plpgsql;

-- Policy for inserting files
CREATE POLICY "Safer media upload policy"
ON storage.objects FOR INSERT
TO authenticated
WITH CHECK (
  bucket_id = 'chat-media' AND
  (
    -- Case 1: Standard conversation media (first part is a UUID)
    (
        is_valid_uuid((regexp_split_to_array(name, '/'))[1]) AND
        (regexp_split_to_array(name, '/'))[1]::uuid IN (
            SELECT conversation_id FROM conversation_members WHERE user_id = auth.uid()
        )
    )
    OR
    -- Case 2: Group avatars (first part is 'group-avatars')
    ((regexp_split_to_array(name, '/'))[1] = 'group-avatars')
  )
);

-- Policy for selecting files
CREATE POLICY "Safer media view policy"
ON storage.objects FOR SELECT
TO authenticated
USING (
  bucket_id = 'chat-media' AND
  (
    -- Case 1: Standard conversation media
    (
        is_valid_uuid((regexp_split_to_array(name, '/'))[1]) AND
        (regexp_split_to_array(name, '/'))[1]::uuid IN (
            SELECT conversation_id FROM conversation_members WHERE user_id = auth.uid()
        )
    )
    OR
    -- Case 2: Group avatars
    ((regexp_split_to_array(name, '/'))[1] = 'group-avatars')
  )
);
