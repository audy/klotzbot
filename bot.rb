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

    # memoize channels
    # channel.name -> channel.id
    $channels = {}

    # fill up channel hash
    Channel.all.map { |c| $channels[c.name] = c.id }

    configure do |c|
      c.server = SERVER || 'irc.freenode.net'
      c.channels = Channel.all.map &:name
      c.nick = NICK || 'klotztest'
      c.password = IRC_PASS
    end

    on :message, /.*/ do |m|
      channel_id = $channels[m.channel.name]
      fail "unknown channel #{m.channel.name}" if channel_id.nil?
      Message.dataset.insert({
        nick: m.user.nick,
        channel_id: channel_id,
        message: m.message,
        created_at: m.time
      })
    end

    auth_on :message, /#{NICK}[:]? stats/ do |m|
      m.reply "#{Message.last.id} messages in #{Channel.count} channels"
    end

    auth_on :message, /#{NICK}[:]? random/ do |m|
      msg = Message.random
      m.reply "(#{msg.id}) [#{msg.channel.name}] #{msg.nick}: #{msg.message}"
    end

    auth_on :message, /#{NICK}[:]? channels/ do |m|
      m.reply puts Channel.all.map(&:name).join(', ')
    end

    auth_on :message, /#{NICK}[:]? last/ do |m|
      msg = Message.last
      m.reply "(#{msg.id}) [#{msg.channel.name}] #{msg.nick}: #{msg.message}"
    end
  end

# reconnect automatically
begin
  @bot.start
rescue Errno::ECONNRESET
  sleep 10
  retry
end
