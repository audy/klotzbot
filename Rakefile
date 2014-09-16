require './environment.rb'

desc 'start interactive console with environment loaded'
task :console do
  Bundler.require :development
  binding.pry
end

namespace :seed do
  task :messages do
    100.times do
      Message.create nick: 'test',
        channel: %w{#test1 #test2 #test3}.sample,
        message: 'test test test!'
    end
  end
end

namespace :db do

  desc 'run migrations'
  task :migrate, [:version] do |t, args|
    Sequel.extension :migration
    if args[:version]
      puts "Migrating to version #{args[:version]}"
      Sequel::Migrator.run(DB,
                           'migrations',
                           target: args[:version].to_i)
    else
      puts "Migrating to latest"
      Sequel::Migrator.run(DB, 'migrations')
    end
  end

  desc 'tail -f the irc stream'
  task :tail do
    DB.loggers = []
    last_time = Time.now
    while true do
      msgs = Message.where { created_at > last_time }.all()
      last_time = Time.now unless msgs.size == 0
      msgs.each do |m|
        puts "#{m[:channel]}\t#{m[:nick]}: #{m[:message]}"
      end
      sleep 1
    end
  end
end

desc 'run the bot'
task :bot do

  channels = 
    if File.exists?('channels.txt')
        channels = File.readlines('channels.txt').map &:strip
    else
        ['#sciencelab2021']
    end

  Cinch::Bot.new do
    configure do |c|
      c.server = ENV['SERVER'] || 'irc.freenode.net'
      c.channels = channels
      c.nick = ENV['NICK'] || 'klotztest'
    end
  
    on :message, /.*/ do |m|
      channel = Channel.find_or_create name: m.channel.name
      Message.create :nick => m.user.nick,
                     :channel => channel,
                     :message => m.message,
                     :created_at => m.time
    end

    on :message, /perrier stats/ do |m|
      if m.nick == ENV['OWNER']
        m.reply "#{Message.count} messages in #{Channel.count} channels"
      end
    end

   end.start

end
