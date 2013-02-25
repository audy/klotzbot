#!/usr/bin/env ruby

# usage: ruby klotzbot.rb

require './environment.rb'
Bundler.require :irc

bot = Cinch::Bot.new do

  configure do |c|
    c.server = SERVER
    c.channels = CHANNELS
    c.nick = NICKNAME
  end

  # log message (ignores anything that starts with NICKNAME)
  on :message, /.*/ do |m|
    unless m.message =~ /^#{NICKNAME}/
      Message.create :text    => m.message,
                     :user    => m.user.nick,
                     :channel => m.channel.name
    end
  end

  # return last message
  on :message, /#{NICKNAME} last/ do |m|
    msg = Message.where(:channel => m.channel.name).sort(:date).last
    unless msg.nil?
      m.reply msg.pretty
    else
      m.reply "no logs for #{m.channel.name}"
    end
  end

  # return a random message
  on :message, /#{NICKNAME} rand/ do |m|
    msg = Message.all(:limit => 1, :skip => rand(Message.count)).first
    m.reply msg.pretty
  end

  # find a message containing the query
  on :message, /#{NICKNAME} find (.*)/ do |m, query|
    msg = Message.sort(:date).last(:text => /#{query}/i)
    if msg.nil?
      m.reply "no results"
    else
      m.reply msg.pretty
    end
  end

  # return first message by nickname
  on :message, /#{NICKNAME} by (.*)/ do |m, nickname|
    msg = Message.sort(:date).last(:user => nickname)
    if msg.nil?
      m.reply "no results"
    else
      m.reply msg.pretty
    end
  end

  # reply with number of times a word occurs in the logs
  on :message, /#{NICKNAME} count (.*)/ do |m, query|
    count = Message.all(:text => /#{query}/).length
    m.reply "#{count}"
  end

end

puts "starting bot"
bot.start
