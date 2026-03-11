require "test_helper"

class PerformerFavoritesControllerTest < ActionDispatch::IntegrationTest
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
    @favorite_performer = performers(:one)
    @not_favorite_performer = performers(:two)
    # リファラーを設定（お気に入り登録・解除後のリダイレクト先として使用）
    @referer = event_performers_path(@event.event_key)
  end

  test "お気に入り登録できる" do
    assert_difference("PerformanceFavorite.count", 2) do
      post performer_favorites_path,
            params: { performer_id: @not_favorite_performer.id },
            headers: { "HTTP_REFERER" => @referer }
    end
    # 登録後はリファラーにリダイレクトされることを確認
    assert_redirected_to @referer
  end

  test "お気に入り解除できる" do
    assert_difference("PerformanceFavorite.count", -2) do
      delete performer_favorites_path,
              params: { performer_id: @favorite_performer.id },
              headers: { "HTTP_REFERER" => @referer }
    end
    # 解除後はリファラーにリダイレクトされることを確認
    assert_redirected_to @referer
  end
end
