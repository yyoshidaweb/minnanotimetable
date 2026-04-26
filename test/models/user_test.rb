require "test_helper"

class UserTest < ActiveSupport::TestCase
  setup do
    @no_ai_usage_user = users(:no_ai_usage)
  end

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

  # 月を跨いだ時にAI利用回数がリセットされる
  test "should reset ai_timetable_count when month has changed" do
    user = @no_ai_usage_user
    user.update!(
      ai_timetable_reset_at: Date.current.prev_month # 最終リセット月が前月の状態を作る
    )
    assert_equal 10, user.ai_timetable_count
    user.ai_timetable_available? # 内部でreset_if_neededが呼ばれる
    user.reload
    assert_equal 0, user.ai_timetable_count
    assert_equal Date.current, user.ai_timetable_reset_at
  end
end
