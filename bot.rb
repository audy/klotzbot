require './environment.rb'

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

    on :message, /perrier[:]? stats/ do |m|
      if m.user.nick == ENV['OWNER']
        m.reply "#{Message.last.id} messages in #{Channel.count} channels"
      end
    end

    on :message, /perrier[:]? random/ do |m|
      msg = Message.random
      m.reply "[#{msg.channel.name}] #{msg.nick}: #{msg.message}"
    end

    on :message, /perrier[:]? channels/ do |m|
      m.reply puts Channel.all.map(&:name).join(', ')
    end

  end


begin
  @bot.start
rescue Errno::ECONNRESET
  sleep 10
  retry
end
