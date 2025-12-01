FROM rust:1.85 AS builder

WORKDIR /app

# Copy dependency files
COPY Cargo.toml Cargo.lock ./

# Copy source code
COPY src ./src
COPY migrations ./migrations

# Build the application
RUN cargo build --release

# Runtime stage
FROM debian:bookworm-slim

RUN apt-get update && apt-get install -y \
    ca-certificates \
    libssl3 \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# Copy the binary from builder stage
COPY --from=builder /app/target/release/klotzbot /app/klotzbot

# Copy migrations
COPY --from=builder /app/migrations /app/migrations

# Create a non-root user
RUN useradd -r -s /bin/false klotzbot
USER klotzbot

CMD ["./klotzbot"]
