# frozen_string_literal: true

ENV["RAILS_ENV"] ||= "test"
require_relative "../config/environment"
require "rails/test_help"

if ENV["COVERAGE"].present?
  require "simplecov"
  require "simplecov-console"

  SimpleCov.start do
    minimum_coverage 100
  end

  SimpleCov.formatter = SimpleCov::Formatter::MultiFormatter.new([
    SimpleCov::Formatter::HTMLFormatter,
    SimpleCov::Formatter::Console
  ])

  SimpleCov::Formatter::Console.use_colors = $stdout.tty?
  SimpleCov::Formatter::Console.show_covered = ENV["COVERAGE_FULL"]
  SimpleCov::Formatter::Console.output_style = "table"
end

module ActiveSupport
  class TestCase
    # Run tests in parallel with specified workers
    parallelize(workers: :number_of_processors)

    # Setup all fixtures in test/fixtures/*.yml for all tests in alphabetical order.
    fixtures :all

    # Add more helper methods to be used by all tests here...
  end
end
