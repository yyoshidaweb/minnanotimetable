require "test_helper"

class PerformancesControllerTest < ActionDispatch::IntegrationTest
  # Devise のテストヘルパーをインクルード
  include Devise::Test::IntegrationHelpers

  # 各テストの前に実行されるセットアップメソッド
  # fixtures に登録済みの event ラベルを利用
  setup do
    # Google 認証のテスト用ユーザーを作成
    @user = users(:one) # fixtures の user を利用
    # テスト用のログイン状態を再現
    sign_in @user
    @event = events(:one)
    @event_two = events(:two)
    @other_event = events(:four)
    @current_day = Date.current
  end

  # 出演情報作成ページ
  test "should get new" do
    get new_event_performance_url(@event.event_key)
    assert_response :success
  end

  # 他者の出演情報作成ページはアクセスできない
  test "should not get new of other user's event" do
    get new_event_performance_url(@other_event.event_key)
    assert_response :not_found
  end

  # 出演情報を作成
  test "should create performance" do
    assert_difference("Performance.for_event(@event).count") do
      post event_performances_path(@event.event_key), params: {
        performance: {
          performer_id: @event.performers.first.id,
          day_id: @event.days.first.id,
          stage_id: @event.stages.first.id,
          start_hour: "10",
          start_minute: "00",
          end_hour: "10",
          end_minute: "30"
        }
      }
    end
    assert_redirected_to edit_timetable_path(@event.event_key)
  end

  # 出演者名だけで出演情報を作成できる
  test "should create performance only with performer" do
    assert_difference("Performance.for_event(@event).count") do
      post event_performances_path(@event.event_key), params: {
        performance: {
          performer_id: @event.performers.first.id
        }
      }
    end
    assert_redirected_to edit_timetable_path(@event.event_key)
  end

  # 出演情報が空文字の場合は作成できない
  test "should not create blank performance" do
    assert_no_difference("Performance.for_event(@event).count") do
      post event_performances_path(@event.event_key), params: {
        performance: {
          performer_id: ""
        }
      }
    end
    assert_response :unprocessable_entity
  end
end
