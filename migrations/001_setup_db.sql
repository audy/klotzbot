-- Initial setup migration
CREATE TABLE IF NOT EXISTS messages (
    id SERIAL PRIMARY KEY,
    nick TEXT,
    message TEXT,
    created_at TIMESTAMP WITHOUT TIME ZONE,
    channel_id INTEGER,
    ip TEXT
);

CREATE TABLE IF NOT EXISTS channels (
    id SERIAL PRIMARY KEY,
    name TEXT,
    active BOOLEAN DEFAULT true,
    network TEXT DEFAULT 'irc.freenode.net'
);

-- Add foreign key constraint only if it doesn't exist
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.table_constraints
        WHERE constraint_name = 'messages_channel_id_fkey'
        AND table_name = 'messages'
    ) THEN
        ALTER TABLE messages ADD CONSTRAINT messages_channel_id_fkey
        FOREIGN KEY (channel_id) REFERENCES channels(id);
    END IF;
END $$;

-- Create indexes for performance (only if they don't exist)
CREATE INDEX IF NOT EXISTS messages_pkey ON messages(id);
CREATE UNIQUE INDEX IF NOT EXISTS channels_channel_name_index ON channels(name);
CREATE INDEX IF NOT EXISTS idx_messages_channel_id ON messages(channel_id);
CREATE INDEX IF NOT EXISTS idx_messages_created_at ON messages(created_at);
