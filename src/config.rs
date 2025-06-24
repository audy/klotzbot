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
}

impl Config {
    pub fn parse_args() -> Self {
        Config::parse()
    }

    pub fn database_url(&self) -> &str {
        &self.database_url
    }
}