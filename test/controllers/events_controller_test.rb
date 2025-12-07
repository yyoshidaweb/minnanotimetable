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
    @other_event = events(:four)
  end

  # 自分が作成したイベント一覧
  test "should index" do
    get events_path
    assert_response :success
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
        event_name_tag_attributes: { name: "" }
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

  # イベント削除処理
  test "should delete event" do
    assert_difference("Event.count", -1) do
      delete event_url(@event.event_key)
    end

    assert_redirected_to events_path
  end

  test "should not delete event of another user" do
    # 他人のイベント削除は失敗し、Event.count は変化しない
    assert_no_difference "Event.count" do
      delete event_url(@other_event.event_key)
    end
  end
end
