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

  # ステージ一覧ページ
  test "should get index" do
    get event_performers_url(@event.event_key)
    assert_response :success
  end

  # 未ログインでもステージ一覧ページにアクセス可能
  test "should get index with logout" do
    sign_out @user
    get event_performers_url(@event.event_key)
    assert_response :success
  end
end
