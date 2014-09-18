channels = Channel.all.map &:name

@bot = Net::YAIL.new(address: ENV['SERVER'] || 'irc.freenode.net',
                     username: 'perrier',
                     realname: 'perrier',
                     nicknames: [ ENV['NICK'] || 'perrier_test' ])

@bot.on_welcome proc {
  channels.each do |channel|
    @bot.join channel
  end
}

@bot.on_msg { |event|
  channel = Channel.find_or_create name: event.channel
  m = Message.create :nick => event.nick,
                     :channel => channel,
                     :message => event.message,
                     :created_at => Time.now

  puts "[#{m.channel}] #{m.nick}: #{m.message}"
}
