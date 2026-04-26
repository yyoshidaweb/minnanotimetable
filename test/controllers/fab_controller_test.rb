require "test_helper"

class FabControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  setup do
    # Google 認証のテスト用ユーザーを作成
    @user = users(:one)
    sign_in @user
    @event = events(:one)
  end

  # FABメニューの表示テスト
  test "should show FAB menu" do
    get fab_path(event_key: @event.event_key)
    assert_response :success
  end
end
