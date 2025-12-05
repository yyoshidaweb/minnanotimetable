require "test_helper"

class TimetablesControllerTest < ActionDispatch::IntegrationTest
  # Devise のテストヘルパーをインクルード
  include Devise::Test::IntegrationHelpers

  setup do
    @event = events(:one)
    # Google 認証のテスト用ユーザーを作成
    @user = users(:one)
    @user_two = users(:two)
    # テスト用のログイン状態を再現
    sign_in @user
  end

  # タイムテーブル編集ページ
  test "should response to edit url" do
    get edit_timetable_url(@event.event_key)
    assert_response :success
  end

  # 作成者本人以外はタイムテーブル編集ページにアクセスできない
  test "should not access to edit url" do
    sign_out @user
    sign_in @user_two
    get edit_timetable_url(@event.event_key)
    # トップページにリダイレクトされる
    assert_redirected_to root_url
  end
end
