require "test_helper"

class HomeControllerTest < ActionDispatch::IntegrationTest
  # トップページ表示
  test "should get index" do
    get "/"
    assert_response :success
  end
end
