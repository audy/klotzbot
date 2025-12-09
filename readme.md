# Klotzbot

An IRC bot that logs to SQL

## Owner Commands

Klotzbot responds to commands from the configured owner:

- `<nick>: stats` - Display total message and channel counts
- `<nick>: random` - Show a random message from the database
- `<nick>: channels` - Show channel statistics (total and active)
- `<nick>: last` - Display the most recent message
- `<nick>: add #channel` - Add a channel to monitoring and join it
- `<nick>: deactivate #channel` - Stop monitoring a channel and leave it
- `<nick>: remove #channel` - Alias for deactivate command

### Example

```bash
cargo run -- \
  --server localhost \
  --port 6667 \
  --owner dev \
  --database-url postgresql://user:pass@localhost/klotzbot
```
### Docker Compose
```yaml
services:
  klotzbot:
    platform: linux/amd64
    image: ghcr.io/audy/klotzbot:master
    entrypoint: /app/klotzbot
    command: --database-url ... --nick ... --server .. --port ... --owner ... --sasl-username ... --sasl-password ...
```

## Database Schema

**`channels`**
- `id` (Primary key)
- `name` (Channel name, e.g., "#rust")
- `active` (Whether bot should join this channel)
- `network` (IRC network hostname)

**`messages`**
- `id` (Primary key)
- `nick` (User nickname)
- `channel_id` (Foreign key to channels)
- `message` (Message content)
- `created_at` (Timestamp)
- `ip` (Resolved IP address, if available)

## License

MIT
