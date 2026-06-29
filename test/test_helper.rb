ENV["RAILS_ENV"] ||= "test"
# Keep Sage's optional on-device models out of the test run: tests stub the
# pipelines they need, and this prevents any accidental model download.
ENV["SAGE_NEURAL"] ||= "off"
require_relative "../config/environment"
require "rails/test_help"

module ActiveSupport
  class TestCase
    # Run tests in a single process; the suite is small and SQLite-backed.
    # parallelize(workers: 1)
  end
end
