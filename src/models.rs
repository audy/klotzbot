use chrono::{DateTime, Utc};
use serde::{Deserialize, Serialize};
use sqlx::{FromRow, PgPool, Row};

#[derive(Debug, Clone, FromRow, Serialize, Deserialize)]
pub struct Channel {
    pub id: i32,
    pub name: String,
    pub active: bool,
    pub network: String,
}

impl Channel {
    pub async fn find_by_name_and_network(
        db: &PgPool,
        name: &str,
        network: &str,
    ) -> Result<Option<Channel>, sqlx::Error> {
        sqlx::query_as::<_, Channel>(
            "SELECT id, name, active, network FROM channels WHERE name = $1 AND network = $2"
        )
        .bind(name)
        .bind(network)
        .fetch_optional(db)
        .await
    }

    pub async fn get_active_channels_for_network(
        db: &PgPool,
        network: &str,
    ) -> Result<Vec<String>, sqlx::Error> {
        let channels = sqlx::query_scalar::<_, String>(
            "SELECT name FROM channels WHERE active = true AND network = $1"
        )
        .bind(network)
        .fetch_all(db)
        .await?;
        Ok(channels)
    }

    pub async fn count(db: &PgPool) -> Result<i64, sqlx::Error> {
        let count = sqlx::query_scalar::<_, i64>("SELECT COUNT(*) FROM channels")
            .fetch_one(db)
            .await?;
        Ok(count)
    }

    pub async fn count_active(db: &PgPool) -> Result<i64, sqlx::Error> {
        let count = sqlx::query_scalar::<_, i64>("SELECT COUNT(*) FROM channels WHERE active = true")
            .fetch_one(db)
            .await?;
        Ok(count)
    }

    pub async fn add_channel(
        db: &PgPool,
        name: &str,
        network: &str,
    ) -> Result<Channel, sqlx::Error> {
        // First check if channel already exists
        if let Some(existing) = Self::find_by_name_and_network(db, name, network).await? {
            if existing.active {
                return Ok(existing); // Already exists and active
            } else {
                // Reactivate existing channel
                sqlx::query("UPDATE channels SET active = true WHERE id = $1")
                    .bind(existing.id)
                    .execute(db)
                    .await?;
                
                return Ok(Channel {
                    id: existing.id,
                    name: existing.name,
                    active: true,
                    network: existing.network,
                });
            }
        }

        // Insert new channel
        let channel = sqlx::query_as::<_, Channel>(
            "INSERT INTO channels (name, active, network) VALUES ($1, true, $2) RETURNING id, name, active, network"
        )
        .bind(name)
        .bind(network)
        .fetch_one(db)
        .await?;

        Ok(channel)
    }

    pub async fn deactivate_channel(
        db: &PgPool,
        name: &str,
        network: &str,
    ) -> Result<Option<Channel>, sqlx::Error> {
        let updated_rows = sqlx::query(
            "UPDATE channels SET active = false WHERE name = $1 AND network = $2 AND active = true"
        )
        .bind(name)
        .bind(network)
        .execute(db)
        .await?;

        if updated_rows.rows_affected() > 0 {
            // Return the updated channel
            Self::find_by_name_and_network(db, name, network).await
        } else {
            Ok(None)
        }
    }
}

#[derive(Debug, Clone, FromRow, Serialize, Deserialize)]
pub struct Message {
    pub id: i32,
    pub nick: String,
    pub channel_id: i32,
    pub message: String,
    pub created_at: DateTime<Utc>,
    pub ip: Option<String>,
}

impl Message {
    pub async fn insert(
        db: &PgPool,
        nick: &str,
        channel_id: i32,
        message: &str,
        ip: Option<&str>,
    ) -> Result<(), sqlx::Error> {
        sqlx::query(
            "INSERT INTO messages (nick, channel_id, message, created_at, ip) VALUES ($1, $2, $3, $4, $5)"
        )
        .bind(nick)
        .bind(channel_id)
        .bind(message)
        .bind(Utc::now())
        .bind(ip)
        .execute(db)
        .await?;
        Ok(())
    }

    pub async fn get_last(db: &PgPool) -> Result<Option<Message>, sqlx::Error> {
        sqlx::query_as::<_, Message>(
            "SELECT id, nick, channel_id, message, created_at, ip FROM messages ORDER BY id DESC LIMIT 1"
        )
        .fetch_optional(db)
        .await
    }

    pub async fn get_random(db: &PgPool) -> Result<Option<Message>, sqlx::Error> {
        let start_id = 81781052i32; // start when we switched to libera.chat
        
        // Get the last message ID
        let last_id: Option<i32> = sqlx::query_scalar("SELECT MAX(id) FROM messages")
            .fetch_one(db)
            .await?;
        let last_id = last_id.unwrap_or(start_id);

        if last_id < start_id {
            return Ok(None);
        }

        // Keep trying random IDs until we find a message
        let mut attempts = 0;
        const MAX_ATTEMPTS: i32 = 100;

        while attempts < MAX_ATTEMPTS {
            let random_id = rand::random::<i32>() % (last_id - start_id + 1) + start_id;
            
            if let Ok(Some(message)) = sqlx::query_as::<_, Message>(
                "SELECT id, nick, channel_id, message, created_at, ip FROM messages WHERE id = $1"
            )
            .bind(random_id)
            .fetch_optional(db)
            .await
            {
                return Ok(Some(message));
            }
            
            attempts += 1;
        }

        // Fallback: get a random message using TABLESAMPLE or ORDER BY RANDOM()
        sqlx::query_as::<_, Message>(
            "SELECT id, nick, channel_id, message, created_at, ip FROM messages WHERE id >= $1 ORDER BY RANDOM() LIMIT 1"
        )
        .bind(start_id)
        .fetch_optional(db)
        .await
    }

    pub async fn count(db: &PgPool) -> Result<i64, sqlx::Error> {
        let count = sqlx::query_scalar::<_, i64>("SELECT COUNT(*) FROM messages")
            .fetch_one(db)
            .await?;
        Ok(count)
    }

    pub async fn get_with_channel(
        db: &PgPool,
        message_id: i32,
    ) -> Result<Option<(Message, Channel)>, sqlx::Error> {
        let row = sqlx::query(
            r#"
            SELECT 
                m.id, m.nick, m.channel_id, m.message, m.created_at, m.ip,
                c.name as channel_name, c.active, c.network
            FROM messages m
            JOIN channels c ON m.channel_id = c.id
            WHERE m.id = $1
            "#
        )
        .bind(message_id)
        .fetch_optional(db)
        .await?;

        if let Some(row) = row {
            let message = Message {
                id: row.get("id"),
                nick: row.get("nick"),
                channel_id: row.get("channel_id"),
                message: row.get("message"),
                created_at: row.get("created_at"),
                ip: row.get("ip"),
            };

            let channel = Channel {
                id: row.get("channel_id"),
                name: row.get("channel_name"),
                active: row.get("active"),
                network: row.get("network"),
            };

            Ok(Some((message, channel)))
        } else {
            Ok(None)
        }
    }
}