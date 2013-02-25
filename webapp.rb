require './environment.rb'

Bundler.require :web

class LogApp < Sinatra::Base

  set :port, 9991

  get '/' do
    @messages = Message.all
    erb "<ul><% @messages.each do |msg| %><li><%= msg.pretty %></li><% end %></ul>"
  end

  get '/imgurs' do
    images = Message.find( {'text' => /imgur/})
    @urls = images.map { |x| x.match(/http:\/\/i\.imgur\.com\/(\w*)\.jpg/)[1] rescue nil}.compact
    erb "<ul><% @urls.each do |img| %><li><a href=\"<%= 'http://i.imgur.com/#{img}.jpg' %>\"></li><% end %></ul>"
  end

end

