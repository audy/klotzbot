require './environment.rb'

@bot =
  Cinch::Bot.new do

    # same as `on` but only works if the user is OWNER
    def auth_on type, regex, &block
      on type, regex do |m|
        if m.user == OWNER
          block.yield(m)
        end
      end
    end

    configure do |c|
      c.server = SERVER
      # only join active channels
      c.channels = Channel.where(active: true).map(&:name)
      c.nick = NICK || 'klotztest'
      c.password = IRC_PASS
    end

    on :message, /.*/ do |m|

      channel = Channel.find(name: m.channel.name)

      # try to get IP address
      # this will crash if cloaking is enabled on the IRC server
      ip = Resolv.getaddress(m.user.host) rescue nil

      Message.dataset.insert({
        nick: m.user.nick,
        channel_id: channel.id,
        message: m.message,
        created_at: m.time,
        ip: ip
      })
    end

    auth_on :message, /#{NICK}[:]? stats/ do |m|
      m.reply "#{Message.last.id} messages in #{Channel.count} channels"
    end

    auth_on :message, /#{NICK}[:]? random/ do |m|
      msg = Message.random
      m.reply "(#{msg.id}) [#{msg.channel.name}] #{msg.nick}: #{msg.message} @ #{msg.created_at.strftime('%D %T')} "
    end

    auth_on :message, /#{NICK}[:]? channels/ do |m|
      m.reply puts Channel.all.map(&:name).join(', ')
    end

    auth_on :message, /#{NICK}[:]? last/ do |m|
      msg = Message.last
      m.reply "(#{msg.id}) [#{msg.channel.name}] #{msg.nick}: #{msg.message}"
    end

    auth_on :message, /#{NICK}[:]? channels/ do |m|
      m.reply "#{Channel.count} channels (#{Channel.where(:active).count} active)"
    end
  end

# silence Cinch logging
@bot.loggers.level = :fatal if production?

# reconnect automatically
begin
  @bot.start
rescue Errno::ECONNRESET
  sleep 10
  retry
end
