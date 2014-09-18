if File.exists?('channels.txt')
    channels = File.readlines('channels.txt').map &:strip
else
    ['#sciencelab2021']
end

# report exceptions in a block to Rollbar
# work-around b/c cinch catches exceptions
def rollbar &block
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
      c.channels = channels
      c.nick = ENV['NICK'] || 'klotztest'
    end

    on :message, /.*/ do |m|
      rollbar {
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
