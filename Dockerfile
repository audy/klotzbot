FROM ruby:2.7.0

WORKDIR /app

ADD . /app

RUN bundle config set without 'development test'

RUN bundle install

ENTRYPOINT ["bundle", "exec", "ruby", "bot.rb"]
