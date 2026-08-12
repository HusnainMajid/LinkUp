-- Voice Calls Table
CREATE TABLE voice_calls (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    caller_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
    receiver_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
    status TEXT NOT NULL CHECK (status IN ('outgoing', 'ringing', 'connecting', 'connected', 'ended', 'rejected', 'cancelled', 'missed', 'failed')),
    type TEXT NOT NULL DEFAULT 'voice',
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    started_at TIMESTAMPTZ,
    ended_at TIMESTAMPTZ,
    duration INTEGER, -- In seconds

    CONSTRAINT no_self_call CHECK (caller_id <> receiver_id)
);

-- Enable RLS
ALTER TABLE voice_calls ENABLE ROW LEVEL SECURITY;

-- RLS Policies
CREATE POLICY "Users can view calls they are involved in"
ON voice_calls FOR SELECT
TO authenticated
USING (auth.uid() = caller_id OR auth.uid() = receiver_id);

CREATE POLICY "Users can initiate calls if they are friends"
ON voice_calls FOR INSERT
TO authenticated
WITH CHECK (
    auth.uid() = caller_id AND
    is_friends(caller_id, receiver_id)
);

CREATE POLICY "Users can update their involved calls"
ON voice_calls FOR UPDATE
TO authenticated
USING (auth.uid() = caller_id OR auth.uid() = receiver_id);

-- Enable Realtime for voice_calls
ALTER PUBLICATION supabase_realtime ADD TABLE voice_calls;

-- Index for performance
CREATE INDEX idx_voice_calls_participants ON voice_calls(caller_id, receiver_id);
CREATE INDEX idx_voice_calls_status ON voice_calls(status);
