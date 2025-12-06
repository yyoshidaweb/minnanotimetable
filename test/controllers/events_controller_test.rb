require "test_helper"

class EventsControllerTest < ActionDispatch::IntegrationTest
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
    assert_select "a[href=?]", show_timetable_path(@event.event_key, d: @day1.date)
    assert_select "a[href=?]", show_timetable_path(@event.event_key, d: @day2.date)
  end

  # 存在しないイベントキーによるタイムテーブル表示失敗のテスト
  test "should 404 if event_key not found" do
    get "/nonexistent-event-key"
    assert_response :not_found
  end

  # 特定日付指定での表示テスト
  test "should show event with specified date" do
    get show_timetable_path(@event.event_key, d: @day2.date)
    assert_response :success
    # 指定日付の全てのパフォーマンスが含まれている
    assert_select "p", text: @performance3.performer.performer_name_tag.name
    assert_select "p", text: @performance4.performer.performer_name_tag.name
    # 他の日付のパフォーマンスが含まれていなければ成功
    assert_select "p", text: @performance1.performer.performer_name_tag.name, count: 0
    assert_select "p", text: @performance2.performer.performer_name_tag.name, count: 0
  end

  # イベント作成ページを表示
  test "should new event" do
    get new_event_url
    assert_response :success
  end

  # イベント作成処理（タグ未存在の場合にイベント作成と同時にタグも作成されることを確認）
  test "should create event and create tag when tag not exists" do
    event_name = "タグ未存在の名前"
    # Event と EventNameTag がそれぞれ1件増えることを確認
    assert_difference([ "Event.count", "EventNameTag.count" ], 1) do
      post events_url, params: {
        event: {
          # ネスト属性でタグ名を送信
          event_name_tag_attributes: { name: event_name },
          description: "説明"
        }
      }
    end
    # 作成されたイベント
    created_event = Event.last
    # 作成されたタグ
    tag = EventNameTag.find_by(name: event_name)

    # タグが作成されていること
    assert_not_nil tag
    # イベントに紐付いていること
    assert_equal tag.id, created_event.event_name_tag_id
    # 正しいリダイレクト先
    assert_redirected_to edit_timetable_url(created_event.event_key)
  end

  # 編集フォームを表示
  test "should get edit" do
    get edit_event_url(@event.event_key)
    assert_response :success
  end

  test "should not update when tag name is blank" do
    patch event_url(@event.event_key), params: {
      event: {
        description: "説明変更",
        event_name_tag_attributes: { name: "" }       # 空なので 422
      }
    }

    assert_response :unprocessable_entity
  end

  test "should update event and replace tag" do
    new_tag_name = "新しいタグ"

    patch event_url(@event.event_key), params: {
      event: {
        description: "説明更新",
        event_name_tag_attributes: { name: new_tag_name }
      }
    }

    assert_redirected_to edit_timetable_url(@event.event_key)

    @event.reload

    # イベントのタグが新しいものに置き換わっていること
    assert_equal new_tag_name, @event.event_name_tag.name

    # Event 本体の値も更新されていること
    assert_equal "説明更新", @event.description
  end
end
