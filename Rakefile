
require 'logger'
require 'bundler'

##
#
# Usage:
# - Install dependencies: bundle install
# - Create the database: rake db:init
# - Start the bot: CHANNELS=#channel1,#channel2 NICK=theklotzster SERVER=irc.freenode.net rake bot
# - log some conversations
# - Dump the db into a tab-separated text file: rake db:dump > messages.txt
#
# The end.
#
##

Bundler.require

DB = Sequel.sqlite 'irc_logs.db',
       :loggers => [Logger.new($STDOUT)]

messages = DB[:messages]

desc 'start interactive console with environment loaded'
task :console do
  Bundler.require :development
  binding.pry
end

namespace :db do

  desc 'initialize the sql database tables'
  task :init do
    DB.create_table :messages do
      primary_key :id
      String :nick
      String :channel
      String :message
      DateTime :created_at, :index => true
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
      print "Fine... "
        DB.drop_table :messages
    else
      puts "Good choice!"
    end
    else
      nuts "Good choice!"
  end
  end

  desc 'dump the db to STDOUT'
  task :dump do
    pbar = ProgressBar.new 'dumping', messages.count()
    puts %w{created_at channel nick message}.join(30.chr)
    DB['select * from messages'].each do |m|
      pbar.inc
      puts [m[:created_at] , m[:channel], m[:nick], m[:message].gsub(30.chr,'')].join(30.chr)
    end
    pbar.finish
  end

  desc 'tail -f the irc stream'
  task :tail do
    time = Time.now
    while true do
      msgs = messages.where { created_at > time }.all()
      msgs.each do |m|
      puts "#{m[:channel]}\t#{m[:nick]}: #{m[:message]}"
    end
    time = Time.now
    sleep 1
  end
  end

  task :stats do
    puts "#{messages.count()} messages."
    puts "#{messages.select_group(:channel).count()} channels."
  end
end

desc 'run the bot'
task :bot do
  Cinch::Bot.new do
    configure do |c|
      c.server = ENV['SERVER'] || 'irc.freenode.net'
      c.channels = (ENV['CHANNELS']|| '#botwars').split(',')
      c.nick = ENV['NICK'] || 'klotztest'
    end
  
    on :message, /.*/ do |m|
      messages.insert :nick => m.user.nick,
                      :channel => m.channel.name,
                      :message => m.message,
                      :created_at => m.time
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
