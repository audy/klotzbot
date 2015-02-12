require './environment.rb'

Bundler.require :web

set :server, 'thin'
set :sockets, []
set :port, ENV['PORT']

def tail &block
  DB.loggers = []
  last_time = Time.now
  puts "listening for new messages..."
  Thread.new {
    while true do
      msgs = Message.last(10).keep_if { |m| m.created_at > last_time }
      last_time = Time.now unless msgs.size == 0
      msgs.each do |m|
        block.yield "#{m.channel.name}\t#{m.nick}: #{m.message}"
      end
      sleep 1
    end
  }
end

get '/' do
  @msg = Message.random
  erb :index
end

__END__
@@ index
<%= @msg.message %> - <%= @msg.nick %> (<%= @msg.channel.name %>) <%= @msg.created_at %>
