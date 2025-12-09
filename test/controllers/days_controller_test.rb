require "test_helper"

class DaysControllerTest < ActionDispatch::IntegrationTest
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

  # 開催日追加ページ
  test "should get new" do
    get new_event_day_url(@event.event_key)
    assert_response :success
  end

  # 開催日を追加
  test "should create day" do
    assert_difference("@event.days.count") do
      post event_days_path(@event.event_key), params: {
        day: { date: "2025-01-01" }
      }
    end
    assert_redirected_to edit_timetable_path(@event.event_key)
  end

  # 開催日が空文字の場合は追加できない
  test "should not create blank day" do
    assert_no_difference("@event.days.count") do
      post event_days_path(@event.event_key), params: {
        day: { date: "" }
      }
    end
    assert_response :unprocessable_entity
  end

  # イベント内の開催日が重複する場合は追加できない
  test "should not create overlapping day" do
    assert_no_difference("@event.days.count") do
      post event_days_path(@event.event_key), params: {
        day: { date: @current_day }
      }
    end
    assert_response :unprocessable_entity
  end

  # 別のイベントと開催日が重複する場合は追加可能
  test "should create overlapping day in other event" do
    assert_difference("@event_two.days.count") do
      post event_days_path(@event_two.event_key), params: {
        day: { date: @current_day }
      }
    end
    assert_redirected_to edit_timetable_path(@event_two.event_key)
  end

  # 開催日削除
  test "should destroy day" do
    assert_difference("@event.days.count", -1) do
      delete event_day_path(@event.event_key, @event.days.first)
    end
    assert_redirected_to edit_timetable_path(@event.event_key)
  end

  # 他者の開催日は削除できない
  test "should not destroy other user's day" do
    assert_no_difference("@other_event.days.count", -1) do
      delete event_day_path(@other_event.event_key, @other_event.days.first)
    end
    assert_response :not_found
  end
end
