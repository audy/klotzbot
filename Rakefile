require './environment.rb'

def summary_stats messages
  start = Time.now
  channels = Message.count { distinct(:channel) }
  messages = Message.count
  stop = Time.now
  "#{messages} messages, #{channels} channels (#{stop - start})"
end

desc 'start interactive console with environment loaded'
task :console do
  Bundler.require :development
  binding.pry
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

  desc 'drop the db'
  task :drop do
    puts "This will drop all the tables. Are you sure? [y/N]"
    drop = STDIN.gets.strip.downcase
    if drop == 'y'
      print "Really?! [y/N] "
      drop = STDIN.gets.strip.downcase
      if drop == 'y'
        print 'do it yourself!'
      else
        puts 'Good Choice!'
      end
    end
  end

  desc 'dump the db to STDOUT as serialized JSON'
  task :dump do
    require 'json'
    pbar = ProgressBar.new 'dumping', Message.count
    puts %w{created_at channel nick message}.join(30.chr)
    Message.each do |m|
      pbar.inc
      puts m.to_json
    end
    pbar.finish
  end

  desc 'tail -f the irc stream'
  task :tail do
    time = Time.now
    while true do
      msgs = Message.where { created_at > time }.all()
      msgs.each do |m|
        puts "#{m[:channel]}\t#{m[:nick]}: #{m[:message]}"
      end
      time = Time.now
      sleep 1
    end
  end

  desc 'print some statistics about database'
  task :stats do
    puts summary_stats(Message.all)
  end
end

desc 'run the bot'
task :bot do

  channels = 
    if File.exists?('channels.txt')
        channels = File.readlines('channels.txt').map &:strip
    else
        ['#botwars']
    end

  Cinch::Bot.new do
    configure do |c|
      c.server = ENV['SERVER'] || 'irc.freenode.net'
      c.channels = channels
      c.nick = ENV['NICK'] || 'klotztest'
    end
  
    on :message, /.*/ do |m|
      messages.insert :nick => m.user.nick,
                      :channel => m.channel.name,
                      :message => m.message,
                      :created_at => m.time
    end

    on :message, /#{ENV['NICK']} stats/ do |m|
      if m.user.nick == ENV['OWNER']
        m.reply summary_stats(messages)
      end
    end
   end.start
end

desc 'start the telnet server'
task :telnet do
  require 'socket'

  @sockets = []
  Socket.tcp_server_loop 8000 do |sock, client_addrinfo|
    @sockets << sock
    Thread.new do
      time = Time.now
      sock.puts "There are #{@sockets.size} clients connected\n\n"
      while true do
        # this kills the CPU?
        msgs = messages.where { created_at > time }.all()
        msgs.each do |m|
          sock.puts "#{m[:channel]}\t#{m[:nick]}: #{m[:message]}"
        end
        time = Time.now
        sleep 1
      end
    end
    @sockets.delete sock
  end

end
