-- Presence: Add last_seen_at if not already present (migration 007 used last_seen)
-- We will stick with last_seen for compatibility with existing profile_model.dart
-- But we'll add an is_online column if it's missing.

-- The mark_messages_as_read RPC is already in 007.

-- RPC to get call history with profile details
CREATE OR REPLACE FUNCTION get_call_history()
RETURNS JSONB AS $$
DECLARE
    result JSONB;
BEGIN
    SELECT jsonb_agg(call_data) INTO result
    FROM (
        SELECT
            vc.*,
            jsonb_build_object(
                'id', p.id,
                'full_name', p.full_name,
                'avatar_url', p.avatar_url,
                'username', p.username
            ) as other_participant_profile
        FROM voice_calls vc
        JOIN profiles p ON (
            CASE
                WHEN vc.caller_id = auth.uid() THEN vc.receiver_id = p.id
                ELSE vc.caller_id = p.id
            END
        )
        WHERE vc.caller_id = auth.uid() OR vc.receiver_id = auth.uid()
        ORDER BY vc.created_at DESC
    ) call_data;

    RETURN COALESCE(result, '[]'::jsonb);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to update presence safely
CREATE OR REPLACE FUNCTION update_user_presence(online BOOLEAN)
RETURNS VOID AS $$
BEGIN
    UPDATE profiles
    SET
        is_online = online,
        last_seen = now()
    WHERE id = auth.uid();
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
