require 'logger'
require 'bundler'

Bundler.require

require './bot.rb'

def test?
  ENV['BOT_ENV'] == 'test'
end

def production?
  ENV['BOT_ENV'] == 'production'
end

# setup rollbar
if production?
  Bundler.require :production

  Rollbar.configure do |config|
    config.access_token = ENV['ROLLBAR_ACCESS_TOKEN']
    config.root = Dir.pwd
    config.framework = 'Perrier'
    config.environment = 'production'
  end
end

# connect to in-memory db if in test environment
database = test? ? 'sqlite:///' : ENV['DATABASE_URL'] || 'sqlite://database.sqlite'

# because computers
Sequel::Model.plugin :force_encoding, 'UTF-8'
Encoding.default_internal = Encoding::UTF_8
Encoding.default_external = Encoding::UTF_8

DB = Sequel.connect database
DB.loggers << Logger.new($stderr) unless test?

if test?
  # migrate *before* running models
  Sequel.extension :migration
  Sequel::Migrator.run(DB, 'migrations')
end

# require models
Dir[File.join(File.expand_path(File.dirname(__FILE__)), 'models', '*.rb')].each { |f|
  require(f)
}
