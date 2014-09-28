def roll &block
  begin
    yield
  rescue Exception => e
    Rollbar.report_exception(e)
  end
end

@bot =
  Cinch::Bot.new do

    configure do |c|
      c.server = ENV['SERVER'] || 'irc.freenode.net'
      c.channels = Channel.all.map &:name
      c.nick = ENV['NICK'] || 'klotztest'
    end

    on :message, /.*/ do |m|
      roll {
        channel = Channel.find_or_create name: m.channel.name
        Message.create :nick => m.user.nick,
                        :channel => channel,
                        :message => m.message,
                        :created_at => m.time
      }
    end

    on :message, /perrier stats/ do |m|
      if m.user.nick == ENV['OWNER']
        m.reply "#{Message.count} messages in #{Channel.count} channels"
      end
    end

  end
