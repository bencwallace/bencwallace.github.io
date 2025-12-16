FROM ruby:3.1

EXPOSE 4000

RUN gem install bundler -v 2.4.22

COPY Gemfile Gemfile.lock ./tmp
RUN bundle install --gemfile=./tmp/Gemfile
