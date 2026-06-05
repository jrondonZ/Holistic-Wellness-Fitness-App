ENV["RAILS_ENV"] ||= "test"
require_relative "../config/environment"
require "rails/test_help"

module ActiveSupport
  class TestCase
    # Run tests in a single process; the suite is small and SQLite-backed.
    # parallelize(workers: 1)
  end
end
