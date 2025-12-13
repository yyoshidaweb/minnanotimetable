require "test_helper"

class PerformersControllerTest < ActionDispatch::IntegrationTest
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

  # 出演者一覧ページ
  test "should get index" do
    get event_performers_url(@event.event_key)
    assert_response :success
  end

  # 未ログインでも出演者一覧ページにアクセス可能
  test "should get index with logout" do
    sign_out @user
    get event_performers_url(@event.event_key)
    assert_response :success
  end

  # 出演者詳細
  test "should get show" do
    performer = @event.performers.first
    get event_performer_url(@event.event_key, performer)
    assert_response :success
  end

  # 未ログインでも出演者詳細にアクセス可能
  test "should get show with logout" do
    sign_out @user
    performer = @event.performers.first
    get event_performer_url(@event.event_key, performer)
    assert_response :success
  end

  # 出演者追加ページ
  test "should get new" do
    get new_event_performer_url(@event.event_key)
    assert_response :success
  end

  # 他者の出演者追加ページはアクセスできない
  test "should not get new of other user's event" do
    get new_event_performer_url(@other_event.event_key)
    assert_response :not_found
  end

  # 出演者作成処理（タグ未存在の場合に出演者作成と同時にタグも作成されることを確認）
  test "should create performer and create tag when tag not exists" do
    performer_name = "タグ未存在の名前"
    assert_difference([ "Performer.count", "PerformerNameTag.count" ], 1) do
      post event_performers_path(@event.event_key), params: {
        performer: {
          # ネスト属性でタグ名を送信
          performer_name_tag_attributes: { name: performer_name },
          description: "説明",
          website_url: "https://example.com"
        }
      }
    end
    # 作成された出演者
    created_performer = Performer.last
    # 作成されたタグ
    tag = PerformerNameTag.find_by(name: performer_name)

    # タグが作成されていること
    assert_not_nil tag
    # 出演者に紐付いていること
    assert_equal tag.id, created_performer.performer_name_tag_id
    # 正しいリダイレクト先
    assert_redirected_to edit_timetable_url(@event.event_key)
  end

  # 出演者が空文字の場合は追加できない
  test "should not create blank performer" do
    assert_no_difference("@event.performers.count") do
      post event_performers_path(@event.event_key), params: {
        performer: {
          # ネスト属性でタグ名を送信
          performer_name_tag_attributes: { name: "" },
          description: "説明",
          website_url: "https://example.com"
        }
      }
    end
    assert_response :unprocessable_entity
  end

  # website_urlがURL形式ではない場合は追加できない
  test "should not create performer if website_url is not url format" do
    performer_name = "タグ未存在の名前"
    assert_no_difference("@event.performers.count") do
      post event_performers_path(@event.event_key), params: {
        performer: {
          # ネスト属性でタグ名を送信
          performer_name_tag_attributes: { name: performer_name },
          description: "説明",
          website_url: "URL形式ではない文字列"
        }
      }
    end
    assert_response :unprocessable_entity
  end

  # イベント内の出演者が重複する場合は追加できない
  test "should not create overlapping performer" do
    overlapping_performer_name = "Performer1"
    assert_no_difference("@event.performers.count") do
      post event_performers_path(@event.event_key), params: {
        performer: {
          # ネスト属性でタグ名を送信
          performer_name_tag_attributes: { name: overlapping_performer_name },
          description: "説明",
          website_url: "https://example.com"
        }
      }
    end
    assert_response :unprocessable_entity
  end

  # 別のイベントと出演者が重複する場合は追加可能
  test "should create overlapping performer in other event" do
    overlapping_performer_name = "Performer1"
    assert_difference("@event_two.performers.count") do
      post event_performers_path(@event_two.event_key), params: {
        performer: {
          # ネスト属性でタグ名を送信
          performer_name_tag_attributes: { name: overlapping_performer_name },
          description: "説明",
          website_url: "https://example.com"
        }
      }
    end
    assert_redirected_to edit_timetable_path(@event_two.event_key)
  end

  # 出演者編集ページ
  test "should get edit performer" do
    performer = @event.performers.first
    get edit_event_performer_url(@event.event_key, performer)
    assert_response :success
  end

  # 他者の出演者編集ページはアクセスできない
  test "should not get edit of other user's event" do
    performer = @event.performers.first
    get edit_event_performer_url(@other_event.event_key, performer)
    assert_response :not_found
  end
end
