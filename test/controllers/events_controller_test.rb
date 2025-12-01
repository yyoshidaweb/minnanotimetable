require "test_helper"

class EventsControllerTest < ActionDispatch::IntegrationTest
  # fixtures に登録済みの event ラベルを利用
  setup do
    @event = events(:test_event)
  end

  # イベントキーによるタイムテーブル表示のテスト
  test "should show event timetable by event_key" do
    get "/#{@event.event_key}"
    assert_response :success
  end

  # 存在しないイベントキーによるタイムテーブル表示失敗のテスト
  test "should 404 if event_key not found" do
    get "/nonexistent-event-key"
    assert_response :not_found
  end
end
