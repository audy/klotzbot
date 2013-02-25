require './environment.rb'

Bundler.require :development

desc 'start console with environment loaded'
task :console do
  binding.pry
end

desc 'dump messages to messages.txt'
task :dump do
  pbar = ProgressBar.new 'saving', Message.size
  File.open('messages.txt', 'w') do |file|
    Message.each do |m|
      pbar.inc
      file.puts [m.date, m.user, m.text].join(',')
    end
  end
  pbar.finish
end

desc 'load messages from messages.txt'
task :load do
end
