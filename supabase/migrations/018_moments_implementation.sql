-- Moments Table
CREATE TABLE moments (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  content TEXT, -- For text moments or image captions
  image_url TEXT, -- For image moments
  type TEXT NOT NULL CHECK (type IN ('text', 'image')),
  background_color TEXT, -- For text moments
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  expires_at TIMESTAMPTZ NOT NULL DEFAULT (NOW() + INTERVAL '24 hours'),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Ensure moment is not completely empty
ALTER TABLE moments ADD CONSTRAINT moment_content_check
  CHECK (content IS NOT NULL OR image_url IS NOT NULL);

ALTER TABLE moments ENABLE ROW LEVEL SECURITY;

-- RLS Policies for moments
CREATE POLICY "Users can view their own moments and friends' moments." ON moments
  FOR SELECT USING (
    auth.uid() = user_id OR
    EXISTS (
      SELECT 1 FROM friend_requests
      WHERE status = 'accepted' AND (
        (sender_id = auth.uid() AND receiver_id = moments.user_id) OR
        (receiver_id = auth.uid() AND sender_id = moments.user_id)
      )
    )
  );

CREATE POLICY "Users can insert their own moments." ON moments
  FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update their own moments." ON moments
  FOR UPDATE USING (auth.uid() = user_id);

CREATE POLICY "Users can delete their own moments." ON moments
  FOR DELETE USING (auth.uid() = user_id);

-- Moment Views Table
CREATE TABLE moment_views (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  moment_id UUID NOT NULL REFERENCES moments(id) ON DELETE CASCADE,
  viewer_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  viewed_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE(moment_id, viewer_id)
);

ALTER TABLE moment_views ENABLE ROW LEVEL SECURITY;

-- RLS Policies for moment_views
CREATE POLICY "Users can insert their own views." ON moment_views
  FOR INSERT WITH CHECK (auth.uid() = viewer_id);

CREATE POLICY "Moment owners can view all views of their moments." ON moment_views
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM moments
      WHERE id = moment_views.moment_id AND user_id = auth.uid()
    ) OR auth.uid() = viewer_id
  );

-- Storage Bucket and Policies
INSERT INTO storage.buckets (id, name, public) VALUES ('moments', 'moments', false) ON CONFLICT (id) DO NOTHING;

CREATE POLICY "Users can upload their own moments." ON storage.objects
  FOR INSERT WITH CHECK (bucket_id = 'moments' AND auth.uid()::text = (storage.foldername(name))[1]);

CREATE POLICY "Users can view friends' moments storage." ON storage.objects
  FOR SELECT USING (
    bucket_id = 'moments' AND (
      auth.uid()::text = (storage.foldername(name))[1] OR
      EXISTS (
        SELECT 1 FROM friend_requests
        WHERE status = 'accepted' AND (
          (sender_id = auth.uid() AND receiver_id::text = (storage.foldername(name))[1]) OR
          (receiver_id = auth.uid() AND sender_id::text = (storage.foldername(name))[1])
        )
      )
    )
  );

CREATE POLICY "Users can delete their own moments storage." ON storage.objects
  FOR DELETE USING (bucket_id = 'moments' AND auth.uid()::text = (storage.foldername(name))[1]);

-- Indexes
CREATE INDEX idx_moments_user_id ON moments(user_id);
CREATE INDEX idx_moments_expires_at ON moments(expires_at);
CREATE INDEX idx_moment_views_moment_id ON moment_views(moment_id);
CREATE INDEX idx_moment_views_viewer_id ON moment_views(viewer_id);

-- Enable Realtime
ALTER PUBLICATION supabase_realtime ADD TABLE moments;
ALTER PUBLICATION supabase_realtime ADD TABLE moment_views;
