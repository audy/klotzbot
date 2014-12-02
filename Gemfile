source "https://rubygems.org"

ruby '2.1.2'

gem 'progressbar'
gem 'cinch'
gem 'sequel'
gem 'sqlite3'
gem 'pg'
gem 'pry'
gem 'rake'


group :web do
  gem 'sinatra'
  gem 'sinatra-websocket'
end

group :production do
  gem 'rollbar', '~> 1.0.0'
end

group :test do
  gem 'rspec'
  gem 'guard-rspec', require: false
end
