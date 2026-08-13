-- User Settings Table
CREATE TABLE user_settings (
  user_id UUID PRIMARY KEY REFERENCES profiles(id) ON DELETE CASCADE,
  theme_mode TEXT NOT NULL DEFAULT 'system' CHECK (theme_mode IN ('light', 'dark', 'system')),
  show_online_status BOOLEAN NOT NULL DEFAULT true,
  show_last_seen BOOLEAN NOT NULL DEFAULT true,
  allow_discovery BOOLEAN NOT NULL DEFAULT true,
  notify_messages BOOLEAN NOT NULL DEFAULT true,
  notify_calls BOOLEAN NOT NULL DEFAULT true,
  notify_moments BOOLEAN NOT NULL DEFAULT true,
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

ALTER TABLE user_settings ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view their own settings." ON user_settings
  FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can update their own settings." ON user_settings
  FOR UPDATE USING (auth.uid() = user_id);

CREATE POLICY "Users can insert their own settings." ON user_settings
  FOR INSERT WITH CHECK (auth.uid() = user_id);

-- Trigger to create default settings on profile creation
CREATE OR REPLACE FUNCTION public.handle_new_user_settings()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO public.user_settings (user_id)
  VALUES (new.id);
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE TRIGGER on_profile_created
  AFTER INSERT ON public.profiles
  FOR EACH ROW EXECUTE PROCEDURE public.handle_new_user_settings();

-- Backfill settings for existing users
INSERT INTO user_settings (user_id)
SELECT id FROM profiles
ON CONFLICT (user_id) DO NOTHING;
