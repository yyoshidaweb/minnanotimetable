ENV["RAILS_ENV"] ||= "test"
require_relative "../config/environment"
require "rails/test_help"
# 全テストでstubを使用できるようにするため、minitest/mockをrequireする
require "minitest/mock"

module ActiveSupport
  class TestCase
    # Run tests in parallel with specified workers
    parallelize(workers: :number_of_processors)

    # fixturesを全て読み込む
    fixtures :all

    # Add more helper methods to be used by all tests here...
  end
end
