FROM ruby:2.7

EXPOSE 4000

RUN gem install bundler -v 2.4.22

WORKDIR /workspace
COPY . .
RUN bundle install

CMD ["bundle", "exec", "jekyll", "serve", "-H", "0.0.0.0", "--livereload"]
