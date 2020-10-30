FROM ruby:2.7-alpine
WORKDIR /app
COPY Gemfile Gemfile.lock ./
RUN bundle install
COPY . .
CMD ["bundle", "exec", "ruby", "app.rb"]
