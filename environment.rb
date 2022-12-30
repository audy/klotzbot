require 'logger'
require 'resolv'
require 'bundler'
require 'pry'

Bundler.require

NICK          = ENV['NICK']
SERVER        = ENV['SERVER']
PORT          = Integer(ENV['PORT'])
IRC_PASS      = ENV['IRC_PASS']
OWNER         = ENV['OWNER']
BOT_ENV       = ENV['BOT_ENV']
DATABASE_URL  = ENV['DATABASE_URL']
SASL_USERNAME = ENV['SASL_USERNAME']
SASL_PASSWORD = ENV['SASL_PASSWORD']

def test?
  BOT_ENV == 'test'
end

def production?
  BOT_ENV == 'production'
end

# setup rollbar
Bundler.require(:production) if production?

# connect to in-memory db if in test environment
database = test? ? 'sqlite:///' : DATABASE_URL || 'sqlite://database.sqlite'

# because computers
Sequel::Model.plugin :force_encoding, 'UTF-8'
Encoding.default_internal = Encoding::UTF_8
Encoding.default_external = Encoding::UTF_8

DB = Sequel.connect database

if test?
  # migrate *before* running models
  Sequel.extension :migration
  Sequel::Migrator.run(DB, 'migrations')
end

# require models
Dir[File.join(File.expand_path(File.dirname(__FILE__)), 'models', '*.rb')].each { |f|
  require(f)
}
