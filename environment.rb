require 'logger'
require 'bundler'

Bundler.require

def test?
  ENV['BOT_ENV'] == 'test'
end

# connect to in-memory db if in test environment
database = test? ? 'sqlite:///' : ENV['DATABASE_URL'] || 'sqlite://database.sqlite'

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
