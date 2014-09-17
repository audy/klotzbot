require './environment.rb'
require 'json'

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

  task :dump do
    File.open(ENV['DATA'], 'w') do |handle|
      Message.each do |m|
        dat = { message: m.message, nick: m.nick, channel: m.channel.name,
              created_at: m.created_at }
        handle.puts dat.to_json
      end
    end
  end

  task :load do

    channels = Hash.new { |h, k| h[k] = Channel.find_or_create(name: k).id }

    File.open(ENV['DATA']) do |handle|
      DB.loggers = []
      pbar = ProgressBar.new 'loading', `wc -l db.dump`.split[0].to_i
      handle.each do |line|
        pbar.inc
        dat = JSON.parse(line)
        m = Message.create message: dat['message'],
                        nick: dat['nick'],
                        channel_id: channels[dat['channel']],
                        created_at: dat['created_at']
      end
      pbar.finish
      puts "#{Message.count} messages and #{Channel.count} channels"
    end
  end

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
        puts "#{m.channel.name}\t#{m.nick}: #{m.message}"
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
      if m.user.nick == ENV['OWNER']
        m.reply "#{Message.count} messages in #{Channel.count} channels"
      end
    end

   end.start

end
