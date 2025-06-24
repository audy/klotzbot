-- Initial setup migration
CREATE TABLE IF NOT EXISTS messages (
    id SERIAL PRIMARY KEY,
    nick VARCHAR NOT NULL,
    channel VARCHAR NOT NULL,
    message TEXT NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS channels (
    id SERIAL PRIMARY KEY,
    name VARCHAR UNIQUE NOT NULL,
    active BOOLEAN NOT NULL DEFAULT true,
    network VARCHAR NOT NULL DEFAULT 'irc.freenode.net'
);

-- Add foreign key relationship
ALTER TABLE messages 
ADD COLUMN channel_id INTEGER REFERENCES channels(id),
ADD COLUMN ip VARCHAR;

-- Create indexes for performance
CREATE INDEX IF NOT EXISTS idx_messages_channel_id ON messages(channel_id);
CREATE INDEX IF NOT EXISTS idx_messages_created_at ON messages(created_at);
CREATE INDEX IF NOT EXISTS idx_channels_name_network ON channels(name, network);
