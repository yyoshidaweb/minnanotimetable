require "test_helper"

class EventsControllerTest < ActionDispatch::IntegrationTest
  # fixtures に登録済みの event ラベルを利用
  setup do
    @event = events(:one)
    @day1 = days(:one)
    @day2 = days(:two)
    @performance1 = performances(:one)
    @performance2 = performances(:two)
    @performance3 = performances(:three)
    @performance4 = performances(:four)
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
    # 指定日付の全てのパフォーマンスが含まれている
    assert_select "p", text: @performance3.performer.performer_name_tag.name
    assert_select "p", text: @performance4.performer.performer_name_tag.name
    # 他の日付のパフォーマンスが含まれていなければ成功
    assert_select "p", text: @performance1.performer.performer_name_tag.name, count: 0
    assert_select "p", text: @performance2.performer.performer_name_tag.name, count: 0
  end
end
