FROM ruby:3.3.1-bookworm

WORKDIR /app

ADD . /app

RUN bundle install

ENTRYPOINT ["ruby", "bot.rb"]
