require 'bundler'
Bundler.require

NICKNAME = 'klotzbot'
SERVER   = 'irc.freenode.net'
CHANNELS = [ '#heyaudy' ]

MongoMapper.connection = Mongo::Connection.new '127.0.0.1'
MongoMapper.database   = 'klotzbot'

require './models.rb'
