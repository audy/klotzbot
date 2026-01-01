use crate::config::Config;
use crate::models::{Channel, Message as DbMessage};
use anyhow::{Context, Result};
use futures::prelude::*;
use irc::client::prelude::*;
use regex::Regex;
use sqlx::PgPool;
use tracing::{debug, error, info, warn};

pub struct KlotzBot {
    config: Config,
    db: PgPool,
    client: Client,
}

impl KlotzBot {
    pub async fn new(config: Config, db: PgPool) -> Result<Self> {
        // Get active channels for this network
        let channels = Channel::get_active_channels_for_network(&db, &config.server)
            .await
            .context("Failed to get active channels")?;

        let mut irc_config = irc::client::data::Config {
            nickname: Some(config.nick.clone()),
            nick_password: config.sasl_password.clone(),
            server: Some(config.server.clone()),
            port: Some(config.port),
            use_tls: Some(true),
            channels: channels,
            burst_window_length: config.burst_window_length,
            max_messages_in_burst: config.max_messages_in_burst,
            ..Default::default()
        };

        if let Some(ref password) = config.irc_pass {
            irc_config.password = Some(password.clone());
        }

        // Note: SASL support might need to be configured differently depending on the IRC library version
        // For now, we'll skip SASL configuration as the field names may have changed

        let client = Client::from_config(irc_config).await?;

        Ok(KlotzBot { config, db, client })
    }

    pub async fn run(&mut self) -> Result<()> {
        let mut stream = self.client.stream()?;

        info!("Starting IRC bot...");
        self.client.identify()?;

        info!("Connected to IRC!");

        while let Some(irc_message) = stream.next().await.transpose()? {
            if let Err(e) = self.handle_irc_message(irc_message).await {
                error!("Error handling message: {}", e);
            }
        }

        Ok(())
    }

    async fn handle_irc_message(&self, message: irc::proto::Message) -> Result<()> {
        match &message.command {
            Command::PRIVMSG(target, msg) => {
                self.handle_privmsg(target, msg, &message).await?;
            }
            _ => {
                debug!("{:?}", message);
            }
        }
        Ok(())
    }

    async fn handle_privmsg(
        &self,
        target: &str,
        msg: &str,
        irc_msg: &irc::proto::Message,
    ) -> Result<()> {
        // Skip private messages, only handle channel messages
        if !target.starts_with('#') {
            return Ok(());
        }

        let nick = irc_msg.source_nickname().unwrap_or("unknown");

        // Find the channel in the database
        let channel = Channel::find_by_name_and_network(&self.db, target, &self.config.server)
            .await
            .context("Failed to find channel")?;

        let channel = match channel {
            Some(c) => c,
            None => {
                warn!("Channel {} not found in database", target);
                return Ok(());
            }
        };

        // Store message in database
        DbMessage::insert(&self.db, nick, channel.id, msg, None)
            .await
            .context("Failed to insert message")?;

        // Handle bot commands if the message is directed at us
        if self.is_owner(nick) {
            self.handle_owner_commands(target, msg).await?;
        }

        Ok(())
    }

    fn is_owner(&self, nick: &str) -> bool {
        nick == self.config.owner
    }

    async fn handle_owner_commands(&self, target: &str, msg: &str) -> Result<()> {
        let nick_pattern = format!(r"{}[:]?\s+", regex::escape(&self.config.nick));

        if let Ok(stats_regex) = Regex::new(&format!("{}stats", nick_pattern)) {
            if stats_regex.is_match(msg) {
                let message_count = DbMessage::count(&self.db).await?;
                let channel_count = Channel::count(&self.db).await?;
                let response = format!("{} messages in {} channels", message_count, channel_count);
                self.client.send_privmsg(target, &response)?;
                return Ok(());
            }
        }

        if let Ok(random_regex) = Regex::new(&format!("{}random", nick_pattern)) {
            if random_regex.is_match(msg) {
                if let Some(random_msg) = DbMessage::get_random(&self.db).await? {
                    if let Some((msg, channel)) =
                        DbMessage::get_with_channel(&self.db, random_msg.id).await?
                    {
                        let response = format!(
                            "({}) [{}] {}: {} @ {}",
                            msg.id,
                            channel.name,
                            msg.nick,
                            msg.message,
                            msg.created_at.format("%m/%d/%y %H:%M:%S")
                        );
                        self.client.send_privmsg(target, &response)?;
                    }
                }
                return Ok(());
            }
        }

        if let Ok(channels_regex) = Regex::new(&format!("{}channels", nick_pattern)) {
            if channels_regex.is_match(msg) {
                let channel_count = Channel::count(&self.db).await?;
                let active_count = Channel::count_active(&self.db).await?;
                let response = format!("{} channels ({} active)", channel_count, active_count);
                self.client.send_privmsg(target, &response)?;
                return Ok(());
            }
        }

        if let Ok(last_regex) = Regex::new(&format!("{}last", nick_pattern)) {
            if last_regex.is_match(msg) {
                if let Some(last_msg) = DbMessage::get_last(&self.db).await? {
                    if let Some((msg, channel)) =
                        DbMessage::get_with_channel(&self.db, last_msg.id).await?
                    {
                        let response = format!(
                            "({}) [{}] {}: {}",
                            msg.id, channel.name, msg.nick, msg.message
                        );
                        self.client.send_privmsg(target, &response)?;
                    }
                }
                return Ok(());
            }
        }

        if let Ok(join_regex) = Regex::new(&format!("{}join\\s+(#\\S+)", nick_pattern)) {
            if let Some(captures) = join_regex.captures(msg) {
                if let Some(channel_name) = captures.get(1) {
                    let channel_name = channel_name.as_str();
                    if let Err(e) = self.client.send_join(channel_name) {
                        let response = format!("Failed to join {}: {}", channel_name, e);
                        self.client.send_privmsg(target, &response)?;
                    } else {
                        let response = format!("Joined {}", channel_name);
                        self.client.send_privmsg(target, &response)?;
                    }
                }
                return Ok(());
            }
        }

        if let Ok(add_regex) = Regex::new(&format!("{}add\\s+(#\\S+)", nick_pattern)) {
            if let Some(captures) = add_regex.captures(msg) {
                if let Some(channel_name) = captures.get(1) {
                    let channel_name = channel_name.as_str();
                    match Channel::add_channel(&self.db, channel_name, &self.config.server).await {
                        Ok(channel) => {
                            // Join the channel
                            if let Err(e) = self.client.send_join(channel_name) {
                                warn!("Failed to join channel {}: {}", channel_name, e);
                                let response = format!(
                                    "Added channel {} to database but failed to join: {}",
                                    channel_name, e
                                );
                                self.client.send_privmsg(target, &response)?;
                            } else {
                                let response = if channel.active {
                                    format!("Channel {} was already active", channel_name)
                                } else {
                                    format!("Added and joined channel {}", channel_name)
                                };
                                self.client.send_privmsg(target, &response)?;
                            }
                        }
                        Err(e) => {
                            let response = format!("Failed to add channel {}: {}", channel_name, e);
                            self.client.send_privmsg(target, &response)?;
                        }
                    }
                }
                return Ok(());
            }
        }

        if let Ok(deactivate_regex) =
            Regex::new(&format!("{}(?:deactivate|remove)\\s+(#\\S+)", nick_pattern))
        {
            if let Some(captures) = deactivate_regex.captures(msg) {
                if let Some(channel_name) = captures.get(1) {
                    let channel_name = channel_name.as_str();
                    match Channel::deactivate_channel(&self.db, channel_name, &self.config.server)
                        .await
                    {
                        Ok(Some(_)) => {
                            // Part the channel
                            if let Err(e) = self.client.send_part(channel_name) {
                                warn!("Failed to part channel {}: {}", channel_name, e);
                                let response = format!(
                                    "Deactivated channel {} in database but failed to part: {}",
                                    channel_name, e
                                );
                                self.client.send_privmsg(target, &response)?;
                            } else {
                                let response =
                                    format!("Deactivated and left channel {}", channel_name);
                                self.client.send_privmsg(target, &response)?;
                            }
                        }
                        Ok(None) => {
                            let response = format!(
                                "Channel {} was not found or already inactive",
                                channel_name
                            );
                            self.client.send_privmsg(target, &response)?;
                        }
                        Err(e) => {
                            let response =
                                format!("Failed to deactivate channel {}: {}", channel_name, e);
                            self.client.send_privmsg(target, &response)?;
                        }
                    }
                }
                return Ok(());
            }
        }

        Ok(())
    }
}
