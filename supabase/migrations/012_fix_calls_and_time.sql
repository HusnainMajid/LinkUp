-- Improve get_call_history to ensure UTC timestamps and correct join for both directions
CREATE OR REPLACE FUNCTION get_call_history()
RETURNS JSONB AS $$
DECLARE
    result JSONB;
BEGIN
    SELECT jsonb_agg(call_data) INTO result
    FROM (
        SELECT
            vc.id,
            vc.caller_id,
            vc.receiver_id,
            vc.status,
            vc.type,
            vc.duration,
            -- Force ISO8601 UTC string for consistent parsing in Dart
            to_char(vc.created_at AT TIME ZONE 'UTC', 'YYYY-MM-DD"T"HH24:MI:SS"Z"') as created_at_utc,
            jsonb_build_object(
                'id', p.id,
                'full_name', p.full_name,
                'avatar_url', p.avatar_url,
                'username', p.username
            ) as other_participant_profile
        FROM voice_calls vc
        JOIN profiles p ON (
            (vc.caller_id = auth.uid() AND vc.receiver_id = p.id) OR
            (vc.receiver_id = auth.uid() AND vc.caller_id = p.id)
        )
        WHERE vc.caller_id = auth.uid() OR vc.receiver_id = auth.uid()
        ORDER BY vc.created_at DESC
    ) call_data;

    RETURN COALESCE(result, '[]'::jsonb);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
