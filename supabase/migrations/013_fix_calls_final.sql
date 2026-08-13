-- Simplify get_call_history and ensure both directions are visible
-- Using Unix milliseconds for maximum reliability across timezones
CREATE OR REPLACE FUNCTION get_call_history()
RETURNS JSONB AS $$
DECLARE
    result JSONB;
BEGIN
    SELECT jsonb_agg(call_data) INTO result
    FROM (
        SELECT
            vc.*,
            (EXTRACT(EPOCH FROM vc.created_at) * 1000)::BIGINT as created_at_ms,
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
        WHERE (vc.caller_id = auth.uid() OR vc.receiver_id = auth.uid())
        ORDER BY vc.created_at DESC
    ) call_data;

    RETURN COALESCE(result, '[]'::jsonb);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
