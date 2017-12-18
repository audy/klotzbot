FROM ruby:onbuild

WORKDIR /app

ADD . /app

ENTRYPOINT ["ruby", "bot.rb"]
