source "https://rubygems.org"

gem "rails", "~> 8.1"

gem 'whenever', require: false
gem "concurrent-ruby-edge", "~> 0.7.1", require: "concurrent-edge"
gem "importmap-rails"
gem "jbuilder"
gem "kamal"
gem "maxmind-db"
gem "propshaft"
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

  gem "rubocop"
  gem "rubocop-rails"

  gem "guard"
  gem "guard-minitest"
  gem "guard-rubocop"

  # TODO these should be required deps? allow for other deploy strategies?
  # Deployment
  gem "capistrano", "~> 3.18"
  #gem "capistrano-puma"
  gem "capistrano3-puma", github: "seuros/capistrano-puma"
  gem "capistrano-rails", "~> 1.4"
  gem "capistrano-rbenv", "~> 2.1", ">= 2.1.4"
  #gem "capistrano-solid_queue", require: false
  gem "ed25519", ">= 1.2", "< 2.0"
  gem "bcrypt_pbkdf", ">= 1.0", "< 2.0"
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
