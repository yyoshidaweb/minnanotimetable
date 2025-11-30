ENV["RAILS_ENV"] ||= "test"
require_relative "../config/environment"
require "rails/test_help"

module ActiveSupport
  class TestCase
    # Run tests in parallel with specified workers
    parallelize(workers: :number_of_processors)

    # fixturesファイルを上から順番に読み込む
    fixtures :users
    fixtures :event_name_tags
    fixtures :performer_name_tags
    fixtures :stage_name_tags
    fixtures :events
    fixtures :performers
    fixtures :stages
    fixtures :days
    fixtures :performances
    fixtures :event_favorites
    fixtures :performer_favorites

    # Add more helper methods to be used by all tests here...
  end
end
