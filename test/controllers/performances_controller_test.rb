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

  # 出演情報追加ページ
  test "should get new" do
    get new_event_performance_url(@event.event_key)
    assert_response :success
  end

  # 他者の出演情報追加ページはアクセスできない
  test "should not get new of other user's event" do
    get new_event_performance_url(@other_event.event_key)
    assert_response :not_found
  end
end
