require "test_helper"

class Users::UsersControllerTest < ActionDispatch::IntegrationTest
  # Devise のテストヘルパーをインクルード
  include Devise::Test::IntegrationHelpers

  # fixturesのユーザーをセットアップ
  def setup
    @user = users(:one)
  end

  # ユーザー詳細ページの表示テスト
  test "should get show by username" do
    get user_url(@user.username)
    assert_response :success
  end

  # 存在しない username に対する404エラーテスト
  test "should return 404 for invalid username" do
      get user_url("unknown_username_123")
      assert_response :not_found
  end
end
