# Klotzbot

An IRC bot that logs to SQL

## Features

✨ **Core Functionality**
- Logs all IRC messages to a PostgreSQL database with timestamps
- Tracks channel activity and user participation
- Resolves and stores user IP addresses when possible
- Automatic database schema migrations
- Robust error handling and automatic reconnection

🎯 **Owner Commands**
Klotzbot responds to commands from the configured owner:
- `<nick>: stats` - Display total message and channel counts
- `<nick>: random` - Show a random message from the database
- `<nick>: channels` - Show channel statistics (total and active)
- `<nick>: last` - Display the most recent message
- `<nick>: add #channel` - Add a channel to monitoring and join it
- `<nick>: deactivate #channel` - Stop monitoring a channel and leave it
- `<nick>: remove #channel` - Alias for deactivate command

## Quick Start

### Prerequisites
- Rust 1.75+ (install from [rustup.rs](https://rustup.rs/))
- PostgreSQL database (required)
- IRC server access

### Basic Usage

```bash
# Clone and build
git clone <repository-url>
cd klotzbot
cargo build --release

# Run with minimal configuration
./target/release/klotzbot \
  --server irc.libera.chat \
  --owner yournickname \
  --database-url postgresql://user:password@localhost/klotzbot

# Get help with all options
./target/release/klotzbot --help
```

## Configuration

Klotzbot uses command-line arguments for all configuration:

| Option | Short | Required | Default | Description |
|--------|-------|----------|---------|-------------|
| `--server` | `-s` | ✅ | - | IRC server hostname (e.g., `irc.libera.chat`) |
| `--owner` | `-o` | ✅ | - | Your IRC nickname (for bot commands) |
| `--nick` | `-n` | ❌ | `klotztest` | Bot's IRC nickname |
| `--port` | `-p` | ❌ | `6697` | IRC server port (SSL/TLS) |
| `--database-url` | `-d` | ✅ | - | PostgreSQL connection string |
| `--irc-pass` | | ❌ | - | IRC server password |
| `--sasl-username` | | ❌ | - | SASL authentication username |
| `--sasl-password` | | ❌ | - | SASL authentication password |

### Example Configurations

```bash
cargo run -- \
  --server localhost \
  --port 6667 \
  --owner dev \
  --database-url postgresql://user:pass@localhost/klotzbot
```

## Docker Development

### Build Image
```bash
docker build -f Dockerfile.rust -t klotzbot:latest .
```

### Run Container
```bash
docker run -d \
  --name klotzbot \
  --restart unless-stopped \
  klotzbot:latest \
  --server irc.libera.chat \
  --owner yournick \
  --database-url postgresql://user:pass@db:5432/klotzbot
```

### Docker Compose
```yaml
version: '3.8'
services:
  klotzbot:
    build:
      context: .
      dockerfile: Dockerfile.rust
    restart: unless-stopped
    command: [
      "--server", "irc.libera.chat",
      "--owner", "yournick",
      "--database-url", "postgresql://klotzbot:password@postgres:5432/klotzbot"
    ]
    depends_on:
      - postgres
  
  postgres:
    image: postgres:15
    environment:
      POSTGRES_DB: klotzbot
      POSTGRES_USER: klotzbot
      POSTGRES_PASSWORD: password
    volumes:
      - postgres_data:/var/lib/postgresql/data

volumes:
  postgres_data:
```

## Database Setup

### PostgreSQL
```sql
-- Create database and user
CREATE DATABASE klotzbot;
CREATE USER klotzbot WITH PASSWORD 'your_password';
GRANT ALL PRIVILEGES ON DATABASE klotzbot TO klotzbot;

-- Connection URL format:
-- postgresql://klotzbot:your_password@localhost:5432/klotzbot
```

## Database Schema

Klotzbot automatically creates and maintains these tables:

**channels**
- `id` (Primary key)
- `name` (Channel name, e.g., "#rust")
- `active` (Whether bot should join this channel)
- `network` (IRC network hostname)

**messages**
- `id` (Primary key)
- `nick` (User nickname)
- `channel_id` (Foreign key to channels)
- `message` (Message content)
- `created_at` (Timestamp)
- `ip` (Resolved IP address, if available)

## Development

### Building from Source
```bash
# Clone repository
git clone <repository-url>
cd klotzbot

# Run tests
cargo test

# Check code quality
cargo clippy
cargo fmt --check

# Build release binary
cargo build --release
```

## License

MIT
