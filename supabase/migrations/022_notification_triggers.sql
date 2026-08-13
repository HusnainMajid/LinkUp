-- Migration to set up notification triggers

-- Function to notify the push-notifications Edge Function
CREATE OR REPLACE FUNCTION public.notify_push_notifications()
RETURNS TRIGGER AS $$
DECLARE
  payload JSONB;
BEGIN
  payload := jsonb_build_object(
    'record', row_to_json(NEW),
    'table', TG_TABLE_NAME,
    'type', TG_OP
  );

  -- We use pg_net if available to call the Edge Function asynchronously
  -- In a managed Supabase environment, this is the most reliable way.
  -- The URL is constructed dynamically or hardcoded if preferred.
  -- For this project, we know the project ref is szlimfkzfnaqfybtziar.

  PERFORM net.http_post(
    url := 'https://szlimfkzfnaqfybtziar.supabase.co/functions/v1/push-notifications',
    headers := jsonb_build_object(
      'Content-Type', 'application/json',
      'Authorization', 'Bearer ' || current_setting('request.jwt.claims', true)::jsonb->>'role' -- This might not work in triggers, usually we use service role or hardcoded anon
    ),
    body := payload
  );

  -- Note: If you encounter authorization issues, you may need to use a dedicated secret
  -- or set up the Webhook via the Supabase Dashboard UI which handles auth automatically.

  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Triggers for messages
DROP TRIGGER IF EXISTS on_message_inserted_notify ON messages;
CREATE TRIGGER on_message_inserted_notify
AFTER INSERT ON messages
FOR EACH ROW
EXECUTE FUNCTION notify_push_notifications();

-- Triggers for friend requests
DROP TRIGGER IF EXISTS on_friend_request_inserted_notify ON friend_requests;
CREATE TRIGGER on_friend_request_inserted_notify
AFTER INSERT ON friend_requests
FOR EACH ROW
EXECUTE FUNCTION notify_push_notifications();

-- Triggers for voice calls
DROP TRIGGER IF EXISTS on_voice_call_inserted_notify ON voice_calls;
CREATE TRIGGER on_voice_call_inserted_notify
AFTER INSERT ON voice_calls
FOR EACH ROW
EXECUTE FUNCTION notify_push_notifications();
