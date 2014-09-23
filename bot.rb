
@bot = Net::YAIL.new(address: ENV['SERVER'] || 'irc.freenode.net',
                     username: 'perrier',
                     realname: 'perrier',
                     nicknames: [ ENV['NICK'] || 'perrier_test' ])

@bot.log.level = Logger::DEBUG unless production?


def roll &block
  begin
    yield
  rescue Exception => e
    Rollbar.report_exception(e)
  end
end


@bot.on_welcome proc {
  channels = Channel.all.map &:name
  channels.each do |channel|
    @bot.join channel
    sleep 1
  end
}

@bot.on_msg { |event|
  Thread.new do
    roll {
      channel = Channel.find_or_create name: event.channel

      # fix encoding
      msg = event.message.encode 'UTF-8', { :invalid => :replace,
                                            :undef => :replace }

      m = Message.create :nick       => event.nick,
                         :channel    => channel,
                         :message    => msg,
                         :created_at => Time.now

      puts "[#{m.channel}] #{m.nick}: #{m.message}"
    }
  end
}
