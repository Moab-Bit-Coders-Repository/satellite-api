FROM ruby:2.4

ADD Gemfile /app/
ADD Gemfile.lock /app/

# throw errors if Gemfile has been modified since Gemfile.lock
RUN bundle config --global frozen 1

RUN gem install bundler --no-ri --no-rdoc && \
    cd /app ; bundle install

ADD . /app
RUN chown -R nobody:nogroup /app
USER nobody
ENV RACK_ENV production
EXPOSE 4567
WORKDIR /app

CMD ["ruby", "main.rb"]
