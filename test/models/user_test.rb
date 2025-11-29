require "test_helper"

class UserTest < ActiveSupport::TestCase
  # ユーザー作成時に username が自動生成されることを確認するテスト
  test "username is generated automatically on create" do
    user = User.create!(
      email: "user3@example.com",
      name: "Test User",
      provider: "google_oauth2",
      uid: "test-google-uid-67890",
    )
    # 8バイト以上であること
    assert user.username.bytesize >= 8
  end
end
