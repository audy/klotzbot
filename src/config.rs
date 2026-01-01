use clap::Parser;

#[derive(Debug, Clone, Parser)]
#[command(name = "klotzbot")]
#[command(about = "An IRC logging bot written in Rust")]
pub struct Config {
    /// IRC nickname
    #[arg(short, long, default_value = "klotztest")]
    pub nick: String,

    /// IRC server hostname
    #[arg(short, long)]
    pub server: String,

    /// IRC server port
    #[arg(short, long, default_value = "6697")]
    pub port: u16,

    /// IRC server password (optional)
    #[arg(long)]
    pub irc_pass: Option<String>,

    /// Bot owner nickname (for commands)
    #[arg(short, long)]
    pub owner: String,

    /// PostgreSQL database URL  
    #[arg(short, long)]
    pub database_url: String,

    /// SASL username (optional)
    #[arg(long)]
    pub sasl_username: Option<String>,

    /// SASL password (optional)
    #[arg(long)]
    pub sasl_password: Option<String>,

    /// Run database migrations on startup
    #[arg(long)]
    pub migrate: bool,

    // The maximum number of messages that can be sent in a burst window before they’ll be delayed.
    // Messages are automatically delayed until the start of the next window. The message throttling
    // system maintains the invariant that in the past burst_window_length seconds, the maximum
    // number of messages sent is max_messages_in_burst. This defaults to 15 messages when not
    // specified.
    #[arg(long, default_value = "15")]
    pub max_messages_in_burst: Option<u32>,

    // The amount of time in seconds to consider a window for burst messages. The message throttling
    // system maintains the invariant that in the past burst_window_length seconds, the maximum
    // number of messages sent is max_messages_in_burst. This defaults to 8 seconds when not
    // specified.
    #[arg(long, default_value = "8")]
    pub burst_window_length: Option<u32>,
}

impl Config {
    pub fn parse_args() -> Self {
        Config::parse()
    }

    pub fn database_url(&self) -> &str {
        &self.database_url
    }
}
