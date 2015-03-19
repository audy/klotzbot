require './environment.rb'
require 'json'

DUMP_FILE = ENV['DATA'] || '/dev/stdout'
CHUNK_SIZE = 1000

desc 'start interactive console with environment loaded'
task :console do
  Bundler.require :development
  binding.pry
end

namespace :chan do
  desc 'list channels'
  task :list do
    Channel.all.map { |c| puts "#{c.id} -> #{c.name}" }
  end

  desc 'add a channel'
  task :add, :name do |t, args|
    p Channel.find_or_create(name: args[:name])
  end

  desc 'remove a channel'
  task :rm, :name do |t, args|
    p Channel.find(name: args[:name]).delete
  end

  desc 'channel-based message counts'
  task :stats do
    Message.group_and_count(:channel_id).all.each do |x|
      channel = Channel[x[:channel_id]]
      puts "#{channel.name} -> #{x.values[:count]}"
    end
  end
end


desc 'print random message'
task :random do
  msg = Message.random
  puts "[#{msg.channel.name}] #{msg.nick}: #{msg.message}"
end

desc 'seed database'
namespace :seed do
  task :messages do
    100.times do
      Message.create nick: 'test',
        channel: Channel.find_or_create(name: %w{#test1 #test2 #test3}.sample),
        message: 'test test test!'
    end
  end
end

namespace :db do

  desc 'dump messages to /dev/stdout'
  task :dump do

    # memoize channels
    # channel.name -> channel.id
    $channels = {}

    # fill up channel hash
    Channel.all.map { |c| $channels[c.name] = c.id }


    Message.find_all do |m|
      dat = { message: m.message,
              nick: m.nick,
              channel: $channels[m.channel_id],
              created_at: m.created_at
            }
      puts dat.to_json
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

    colors = %w{red green yellow blue magenta cyan white light_red light_green
    light_yellow light_blue light_magenta light_cyan light_white }

    colormap = Hash.new { |h, k| h[k] = colors.sample }
    DB.loggers = []

    sh 'clear'

    last_time = Time.now
    while true do
      msgs = Message.last(10).keep_if { |m| m.created_at > last_time }
      last_time = Time.now unless msgs.size == 0
      msgs.each do |m|
        chan_name = m.channel.name.send(colormap[m.channel.name])
        puts "#{chan_name}\t#{m.nick}: #{m.message}"
      end
      sleep 1
    end
  end
end
