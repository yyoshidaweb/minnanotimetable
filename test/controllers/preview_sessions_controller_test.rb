require "test_helper"

class PreviewSessionsControllerTest < ActionDispatch::IntegrationTest
  # Devise のテストヘルパーをインクルード
  include Devise::Test::IntegrationHelpers

  # プレビュー環境でログインできることを確認
  test "should create preview session" do
    # 一時的にpreview_environment?をtrueにスタブしてテストする
    ApplicationController.stub(:preview_environment?, true) do
      post "/preview_login"
      assert_redirected_to root_path
    end
  end

  # プレビュー環境でなければ403 Forbiddenが返ることを確認
  test "should not create preview session in not-preview environment" do
    # 一時的にpreview_environment?をfalseにスタブしてテストする
    ApplicationController.stub(:preview_environment?, false) do
      post "/preview_login"
      assert_response :forbidden
    end
  end
end
