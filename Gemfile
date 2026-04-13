source "https://rubygems.org"

gem "rails", "~> 8.1"

gem "concurrent-ruby-edge", "~> 0.7.1", require: "concurrent-edge"
gem "importmap-rails"
gem "revise_auth"
gem "jbuilder"
gem "kamal"
gem "maxmind-db"
gem "propshaft"
gem "tailwindcss-rails"
gem "puma"
gem "rack-cors"
# gem "solid_cache"
gem "solid_queue"
gem "sqlite3"
gem "stimulus-rails"
gem "turbo-rails"
gem "user_agent_parser", "~> 2.18"

# Reduces boot times through caching; required in config/boot.rb
gem "bootsnap", require: false

group :development, :test do
  gem "annotaterb"
  gem "brakeman", require: false
  gem "debug", platforms: %i[ mri windows ], require: "debug/prelude"
  gem "pry"

  gem "minitest-mock"

  gem "rubocop"
  gem "rubocop-minitest"
  gem "rubocop-rails"

  gem "guard"
  gem "guard-minitest"
  gem "guard-rubocop"
end

group :development do
  gem "web-console"
end

group :test do
  gem "capybara"
  gem "selenium-webdriver"
  gem 'simplecov', require: false
  gem "simplecov-console", require: false
end

group :production do
  gem "thruster"
end

gem "view_component", "~> 4.6"
gem "chartkick"
gem "will_paginate"
