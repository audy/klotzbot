ENV['BOT_ENV'] = 'test'

require File.join(File.expand_path(File.dirname(__FILE__)), '..', 'environment.rb')

RSpec.configure do |config|

  # run tests in their own transaction, rolling back afterwards to ensure that
  # tests are isolated.
  config.around :each do |example|
    DB.transaction rollback: :always, auto_savepoint: true do 
      example.run
    end
  end

end
