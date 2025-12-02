require "test_helper"

class EventsControllerTest < ActionDispatch::IntegrationTest
  # fixtures に登録済みの event ラベルを利用
  setup do
    @event = events(:test_event)
    @day1 = days(:day_1)
    @day2 = days(:day_2)
    @perf1 = performances(:one_day_one_performance)
    @perf2 = performances(:two_day_two_performance)
  end

  # デフォルト（最古日付）での表示テスト
  test "should show event timetable by event_key" do
    get "/#{@event.event_key}"
    assert_response :success
    # 全日付へのリンクが含まれている
    assert_select "a[href=?]", event_path(@event.event_key, d: @day1.date)
    assert_select "a[href=?]", event_path(@event.event_key, d: @day2.date)
  end

  # 存在しないイベントキーによるタイムテーブル表示失敗のテスト
  test "should 404 if event_key not found" do
    get "/nonexistent-event-key"
    assert_response :not_found
  end

  # 特定日付指定での表示テスト
  test "should show event with specified date" do
    get event_path(@event.event_key, d: @day2.date)
    assert_response :success
  end
end
