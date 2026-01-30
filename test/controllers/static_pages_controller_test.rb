require "test_helper"

class StaticPagesControllerTest < ActionDispatch::IntegrationTest
  test "should get terms" do
    get terms_path
    assert_response :success
  end

  test "should get privacy" do
    get privacy_path
    assert_response :success
  end
end
