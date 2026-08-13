-- Migration to set up notification triggers

-- Function to notify the push-notifications Edge Function
CREATE OR REPLACE FUNCTION public.notify_push_notifications()
RETURNS TRIGGER AS $$
DECLARE
  payload JSONB;
BEGIN
  -- Construct the payload
  payload := jsonb_build_object(
    'record', row_to_json(NEW),
    'table', TG_TABLE_NAME,
    'type', TG_OP
  );

  -- Call the Edge Function asynchronously
  -- We use a literal JSONB object for headers to avoid parsing errors
  -- We also wrap it in a nested block to prevent notification failures from breaking the message insert
  BEGIN
    PERFORM net.http_post(
      url := 'https://szlimfkzfnaqfybtziar.supabase.co/functions/v1/push-notifications',
      headers := '{"Content-Type": "application/json"}'::jsonb,
      body := payload
    );
  EXCEPTION WHEN OTHERS THEN
    -- Log error or ignore to ensure the main transaction (sending the message) succeeds
    RAISE WARNING 'Push notification trigger failed: %', SQLERRM;
  END;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Ensure triggers are correctly attached
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
