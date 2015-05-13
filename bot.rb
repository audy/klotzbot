require './environment.rb'


@bot =
  Cinch::Bot.new do

    # memoize channels
    # channel.name -> channel.id
    $channels = {}

    # fill up channel hash
    Channel.all.map { |c| $channels[c.name] = c.id }

    configure do |c|
      c.server = ENV['SERVER'] || 'irc.freenode.net'
      c.channels = Channel.all.map &:name
      c.nick = ENV['NICK'] || 'klotztest'
    end

    on :message, /.*/ do |m|
      channel_id = $channels[m.channel.name]
      fail "unknown channel #{m.channel.name}" if channel_id.nil?
      Message.dataset.insert({
        :nick => m.user.nick,
        :channel_id => channel_id,
        :message => m.message,
        :created_at => m.time})
    end

    on :message, /perrier[:]? stats/ do |m|
      if m.user.nick == ENV['OWNER']
        m.reply "#{Message.last.id} messages in #{Channel.count} channels"
      end
    end

    on :message, /perrier[:]? random/ do |m|
      if m.user.nick == ENV['OWNER']
        msg = Message.random
        m.reply "(#{msg.id}) [#{msg.channel.name}] #{msg.nick}: #{msg.message}"
      end
    end

    on :message, /perrier[:]? channels/ do |m|
      if m.user.nick == ENV['OWNER']
        m.reply puts Channel.all.map(&:name).join(', ')
      end
    end

  end


begin
  @bot.start
rescue Errno::ECONNRESET
  sleep 10
  retry
end
