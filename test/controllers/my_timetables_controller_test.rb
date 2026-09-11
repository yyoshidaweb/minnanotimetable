require "test_helper"

class MyTimetablesControllerTest < ActionDispatch::IntegrationTest
  # Devise のテストヘルパーをインクルード
  include Devise::Test::IntegrationHelpers

  setup do
    # Google 認証のテスト用ユーザーを作成
    @user = users(:one)
    @user_two = users(:two)
    # テスト用のログイン状態を再現
    sign_in @user
    @event = events(:one)
    @no_performance_event = events(:no_performance_event)
    @day1 = days(:one)
    @day2 = days(:two)
    @performance1 = performances(:one)
    @performance2 = performances(:two)
    @performance3 = performances(:three)
    @performance4 = performances(:four)
  end

  # 未ログインでもタイムテーブルページにアクセス可能
  test "should get my_timetable with logout" do
    sign_out @user
    get show_my_timetable_path(event_key: @event.event_key, username: @user.username)
    assert_response :success
  end

  # ログイン状態でタイムテーブルページにアクセス可能
  test "should show my_timetable with login" do
    get show_my_timetable_path(event_key: @event.event_key, username: @user.username)
    assert_response :success
  end

  # 出演情報カードとステージ名は詳細ページへ遷移せずモーダルで開く
  test "performance cards and stage names open detail in modal" do
    get show_my_timetable_path(event_key: @event.event_key, username: @user.username)
    assert_response :success
    assert_select "a.stage-header-col[href=?][data-turbo-frame=modal]",
                  event_stage_path(@event.event_key, @performance1.stage)
    assert_select "a[href=?][data-turbo-frame=modal]",
                  event_performer_path(@event.event_key, @performance1.performer)
    assert_select "a#my_timetable_performance_#{@performance1.id}"
  end

  # マイタイムテーブルは検索エンジンにインデックスさせない
  test "my timetable includes noindex robots meta" do
    get show_my_timetable_path(event_key: @event.event_key, username: @user.username)
    assert_response :success
    assert_select "meta[name=robots][content='noindex, nofollow']"
  end

  # マイタイムテーブルもページ全体ではなく内側コンテナのみスクロールする
  test "my timetable page locks body scroll and scrolls inner container only" do
    get show_my_timetable_path(event_key: @event.event_key, username: @user.username)
    assert_response :success
    assert_select "body.h-svh.overflow-hidden"
    assert_select "main.min-h-0.overflow-hidden"
    assert_select "div#my_timetable.h-full"
    assert_select "div.flex-1.min-h-0.overflow-auto.overscroll-none"
  end

  # 出演情報0件の空状態は上下左右中央に表示する
  test "empty my timetable centers the empty state" do
    get show_my_timetable_path(event_key: @no_performance_event.event_key, username: @user.username)
    assert_response :success
    assert_select "div#my_timetable.h-full" do
      assert_select "div.h-full.flex.flex-col.items-center.justify-center"
    end
    assert_select "p", text: /出演情報をお気に入り登録すると/
  end

  test "should not get unpublished my_timetable with logout" do
    sign_out @user
    unpublished_event = events(:unpublished)
    get show_my_timetable_path(event_key: unpublished_event.event_key, username: @user.username)
    assert_response :not_found
  end

  test "should not get unpublished my_timetable by other user" do
    sign_out @user
    sign_in @user_two
    unpublished_event = events(:unpublished)
    get show_my_timetable_path(event_key: unpublished_event.event_key, username: @user.username)
    assert_response :not_found
  end
end
