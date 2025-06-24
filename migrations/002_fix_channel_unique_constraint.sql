-- Fix unique constraint to allow same channel name on different networks
DROP INDEX IF EXISTS channels_channel_name_index;
CREATE UNIQUE INDEX channels_name_network_unique ON channels(name, network);