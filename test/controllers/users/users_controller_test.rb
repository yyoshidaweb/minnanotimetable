require "test_helper"

class Users::UsersControllerTest < ActionDispatch::IntegrationTest
  # Devise のテストヘルパーをインクルード
  include Devise::Test::IntegrationHelpers

  # fixturesのユーザーをセットアップ
  def setup
    @user = users(:one)
  end

  # ユーザー詳細ページの表示テスト
  test "should get show by user_id" do
    get user_url(@user.user_id)
    assert_response :success
  end

  # 存在しない user_id に対する404エラーテスト
  test "should return 404 for invalid user_id" do
      get user_url("unknown_user_id_123")
      assert_response :not_found
  end
end
