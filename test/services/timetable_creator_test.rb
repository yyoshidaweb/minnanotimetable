require "test_helper"

class TimetableCreatorTest < ActionDispatch::IntegrationTest
  # Devise のテストヘルパーをインクルード
  include Devise::Test::IntegrationHelpers

  setup do
    # Google 認証のテスト用ユーザーを作成
    @user = users(:one)
    @user_two = users(:two)
    # テスト用のログイン状態を再現
    sign_in @user
    @event = events(:one)
    @no_performance_event = events(:no_performance_event)
    @day1 = days(:one)
    @day2 = days(:two)
  end

  # タイムテーブルJSONからStage、Performer、Performanceを作成できる
  test "create timetable from json" do
    json = JSON.parse(file_fixture("timetable_json.json").read)

    assert_difference "Stage.count", +2 do
      assert_difference "Performer.count", +3 do
        assert_difference "Performance.count", +3 do
          TimetableCreator.create_from_json(
            json: json,
            event: @no_performance_event,
            day: @day1
          )
        end
      end
    end
  end
end
