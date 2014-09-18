require './environment.rb'
require 'json'

DUMP_FILE = ENV['DATA']
CHUNK_SIZE = 1000

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
    File.open(DUMP_FILE, 'w') do |handle|
      Message.each do |m|
        dat = { message: m.message, nick: m.nick, channel: m.channel.name,
              created_at: m.created_at }
        handle.puts dat.to_json
      end
    end
  end

  task :load do

    channels = Hash.new { |h, k| h[k] = Channel.find_or_create(name: k).id }

    File.open(DUMP_FILE) do |handle|
      DB.loggers = []
      pbar = ProgressBar.new 'loading', `wc -l #{DUMP_FILE}`.split[0].to_i/CHUNK_SIZE
      Message.use_after_commit_rollback = false
      DB.transaction {
        handle.each_slice(CHUNK_SIZE) do |chunk|
          pbar.inc
          dat = chunk.map { |line| JSON.parse(line) }
          dat = dat.map { |x| [ x['message'], x['nick'], channels[x['channel_id']], x['created_at'] ] }
          DB[:messages].import([:message, :nick, :channel_id, :created_at], dat)
        end
      }
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
      msgs = Message.last(10).keep_if { |m| m.created_at > last_time }
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
  @bot.start_listening!
end
