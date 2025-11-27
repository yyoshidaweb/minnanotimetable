require "test_helper"

class UserTest < ActiveSupport::TestCase
  # ユーザー作成時に user_id が自動生成されることを確認するテスト
  test "user_id is generated automatically on create" do
    user = User.create!(
      email: "user3@example.com",
      name: "Test User",
      provider: "google_oauth2",
      uid: "test-google-uid-67890",
    )
    # 8バイト以上であること
    assert user.user_id.bytesize >= 8
  end
end
