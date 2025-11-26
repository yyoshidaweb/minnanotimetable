require "test_helper"

class ProfilesControllerTest < ActionDispatch::IntegrationTest
  # Devise のテストヘルパーをインクルード
  include Devise::Test::IntegrationHelpers

  # 各テストの前に実行されるセットアップメソッド
  def setup
    # Google 認証のテスト用ユーザーを作成
    @user = users(:one) # fixtures の user を利用
    # テスト用のログイン状態を再現
    sign_in @user # ログイン状態を再現
  end

  # プロフィール表示アクションのテスト
  test "should get show when logged in" do
    get profile_url(@user) # ログインユーザーのプロフィールページ
    assert_response :success # 成功レスポンスを期待
  end

  # プロフィール編集アクションのテスト
  test "should get edit when logged in" do
    get edit_profile_url(@user) # ログインユーザーのプロフィール編集ページ
    assert_response :success # 成功レスポンスを期待
  end

  # プロフィール更新アクションのテスト
  test "should update profile when logged in" do
    # PATCHリクエスト（プロフィール更新処理）
    patch profile_url, params: { user: { name: "New Name", user_id: "new_user_id", description: "説明" } }
    @user.reload
    assert_equal "New Name", @user.name
    assert_equal "new_user_id", @user.user_id
    assert_equal "説明", @user.description
  end

  # プロフィール更新アクションのuser_idが重複した場合のテスト
  test "should not update user_id when duplicated" do
    # PATCHリクエスト（プロフィール更新処理）
    patch profile_url, params: { user: { user_id: "efgh5678" } }
    @user.reload
    assert_not_equal "efgh5678", @user.user_id
    # HTTPステータスが422（バリデーションエラー）であることを確認
    assert_response :unprocessable_entity
  end

  # プロフィール更新後のリダイレクトのテスト
  test "should redirect after update profile when logged in" do
    # PATCHリクエスト（プロフィール更新処理）
    patch profile_url, params: { user: { name: "New Name" } }
    assert_redirected_to profile_url # 更新後プロフィール画面へリダイレクト
  end

  # プロフィール削除アクションのテスト
  test "should delete profile when logged in" do
    delete profile_url
    assert_raises(ActiveRecord::RecordNotFound) { @user.reload } # ユーザーが削除されていることを確認
  end

  # プロフィール削除後リダイレクトのテスト
  test "should redirect after delete profile when logged in" do
    delete profile_url
    assert_redirected_to root_url # 削除後ホーム画面へリダイレクト
  end

  # ログアウト時プロフィール更新アクションのテスト
  test "should redirect update when not logged in" do
    sign_out @user
    patch profile_url, params: { user: { name: "Hacker" } }
    assert_redirected_to new_user_session_url # 未ログインは更新不可
  end

  # ログアウト時プロフィール表示アクションのテスト
  test "should redirect show when not logged in" do
    sign_out @user # ログアウト状態を再現
    get profile_url # プロフィールページにアクセス
    assert_redirected_to new_user_session_url # deviseログインページ
  end
end
