-- User Devices Table to store FCM tokens
CREATE TABLE user_devices (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
    fcm_token TEXT NOT NULL,
    platform TEXT, -- 'android', 'ios', 'web'
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    UNIQUE(user_id, fcm_token)
);

-- Enable RLS
ALTER TABLE user_devices ENABLE ROW LEVEL SECURITY;

-- Policies
CREATE POLICY "Users can manage their own device tokens"
ON user_devices FOR ALL
TO authenticated
USING (auth.uid() = user_id)
WITH CHECK (auth.uid() = user_id);

-- Index for performance
CREATE INDEX idx_user_devices_user_id ON user_devices(user_id);

-- Function to handle notification triggers (to be called by webhooks or Edge Functions)
-- In a real setup, we use Supabase Webhooks to call an Edge Function when a message is inserted.

/*
  NOTE: To fully enable notifications, you should set up a Webhook in the Supabase Dashboard:
  - Name: send_message_notification
  - Table: messages
  - Events: INSERT
  - URL: Your Edge Function URL
  - HTTP Method: POST
*/

-- Update latest_message RPC to include sender name for notifications
-- (The RPC get_user_conversations_v4 is already used for the UI, but Edge Functions might need specialized views)
