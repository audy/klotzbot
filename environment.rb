require 'logger'
require 'bundler'

Bundler.require

database = ENV['DATABASE_URL'] || 'sqlite://database.sqlite'


DB = Sequel.connect database

DB.loggers << Logger.new($stderr)

messages = DB[:messages]
