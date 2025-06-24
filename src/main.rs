mod bot;
mod config;
mod models;

use anyhow::{Context, Result};
use bot::KlotzBot;
use config::Config;
use sqlx::PgPool;
use std::time::Duration;
use tracing::{error, info};
use tracing_subscriber;

#[tokio::main]
async fn main() -> Result<()> {
    // Initialize tracing
    tracing_subscriber::fmt::init();

    // Parse command line arguments
    let config = Config::parse_args();

    // Connect to database
    let db = connect_database(&config).await?;

    // Run migrations
    sqlx::migrate!("./migrations")
        .run(&db)
        .await
        .context("Failed to run migrations")?;

    // Main bot loop with reconnection logic
    loop {
        match run_bot(&config, &db).await {
            Ok(_) => {
                info!("Bot stopped normally");
                break;
            }
            Err(e) => {
                error!("Bot error: {}", e);
                error!("SOMETHING WENT WRONG WITH CONNECTION ARGH");
                
                // Wait before reconnecting
                tokio::time::sleep(Duration::from_secs(10)).await;
                info!("Attempting to reconnect...");
            }
        }
    }

    Ok(())
}

async fn connect_database(config: &Config) -> Result<PgPool> {
    let database_url = config.database_url();
    
    if database_url.starts_with("sqlite") {
        return Err(anyhow::anyhow!(
            "SQLite support is limited due to type compatibility issues. Please use PostgreSQL for best results.\n\
            Example: postgresql://user:password@localhost:5432/klotzbot"
        ));
    }
    
    info!("Connecting to PostgreSQL database: {}", database_url);
    
    let pool = PgPool::connect(database_url)
        .await
        .context("Failed to connect to PostgreSQL database")?;

    Ok(pool)
}

async fn run_bot(config: &Config, db: &PgPool) -> Result<()> {
    let mut bot = KlotzBot::new(config.clone(), db.clone()).await?;
    bot.run().await
}