# Klotzbot

A high-performance IRC logging bot rewritten in Rust by Austin G. Davis-Richardson.

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

🔧 **Technical Features**
- Modern async/await Rust architecture for high performance
- Memory-safe operations with zero-cost abstractions
- Command-line interface with comprehensive help
- Docker support for easy deployment
- Configurable logging levels and output

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

**Basic setup for Libera.Chat:**
```bash
klotzbot --server irc.libera.chat --owner mynick
```

**With PostgreSQL database:**
```bash
klotzbot \
  --server irc.libera.chat \
  --owner mynick \
  --nick mybot \
  --database-url postgresql://botuser:password@db.example.com/irclog
```

**With custom port:**
```bash
cargo run -- \
  --server localhost \
  --port 6667 \
  --owner dev \
  --database-url postgresql://user:pass@localhost/klotzbot
```

## Docker Deployment

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

### Project Structure
```
klotzbot/
├── src/
│   ├── main.rs          # Application entry point
│   ├── config.rs        # CLI argument parsing
│   ├── bot.rs           # IRC bot implementation  
│   └── models.rs        # Database models
├── migrations/          # SQL migrations
├── Cargo.toml          # Rust dependencies
├── Dockerfile.rust     # Docker build configuration
└── readme.md          # This file
```

## Comparison with Ruby Version

| Feature | Ruby (Cinch) | Rust |
|---------|--------------|------|
| Memory Usage | ~50MB | ~5MB |
| CPU Usage | Higher | Lower |
| Startup Time | ~2s | ~0.1s |
| Dependencies | Many gems | Statically linked |
| Safety | Runtime errors | Compile-time guarantees |
| Concurrency | Threads | Async/await |

## Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## License

This project maintains the same license as the original Ruby version.

## Troubleshooting

**Bot won't connect to IRC:**
- Verify server hostname and port
- Check if SSL/TLS is required (default port 6697 uses SSL)
- Ensure nickname isn't already in use

**Database connection fails:**
- Verify PostgreSQL is running and accessible
- Check connection string format
- Ensure database and user exist with proper permissions

**Commands not working:**
- Confirm you're using the exact owner nickname specified
- Try addressing the bot directly: `botname: stats`
- Check bot logs for error messages

**Docker issues:**
- Ensure container can reach IRC server (check firewall/network)
- Verify database container is running and accessible
- Check container logs: `docker logs klotzbot`
