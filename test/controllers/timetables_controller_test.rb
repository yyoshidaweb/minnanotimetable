require "test_helper"

class TimetablesControllerTest < ActionDispatch::IntegrationTest
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
    @no_performance_event_day = days(:no_performance_event_day)
    @performance1 = performances(:one)
    @performance2 = performances(:two)
    @performance3 = performances(:three)
    @performance4 = performances(:four)
    @json = JSON.parse(file_fixture("timetable_json.json").read)
  end

  # 未ログインでもタイムテーブルページにアクセス可能
  test "should get timetable with logout" do
    sign_out @user
    get show_timetable_path(@event.event_key)
    assert_response :success
  end

  # デフォルト（最古日付）での表示テスト
  test "should show event timetable by event_key" do
    get show_timetable_path(@event.event_key)
    assert_response :success
    # 全日付へのリンクが含まれている
    assert_select "a[href=?]", show_timetable_path(@event.event_key, d: @day1.date)
    assert_select "a[href=?]", show_timetable_path(@event.event_key, d: @day2.date)
  end

  # 存在しないイベントキーによるタイムテーブル表示失敗のテスト
  test "should 404 if event_key not found" do
    get "/nonexistent-event-key"
    assert_response :not_found
  end

  # 特定日付指定での表示テスト
  test "should show event with specified date" do
    get show_timetable_path(@event.event_key, d: @day2.date)
    assert_response :success
    # 指定日付の全てのパフォーマンスが含まれている
    assert_select "p", text: @performance3.performer.performer_name_tag.name
    assert_select "p", text: @performance4.performer.performer_name_tag.name
    # 他の日付のパフォーマンスが含まれていなければ成功
    assert_select "p", text: @performance1.performer.performer_name_tag.name, count: 0
    assert_select "p", text: @performance2.performer.performer_name_tag.name, count: 0
  end

  # 出演情報が0件の場合もタイムテーブルを表示できる
  test "should show event timetable by event_key when no performances" do
    get show_timetable_path(@no_performance_event.event_key)
    assert_response :success
  end

  # AIタイムテーブル作成が成功する
  test "should create timetable with AI" do
    sign_out @user
    sign_in @user_two
    # TimetableExtractorをモック（APIは利用せず、常に固定JSONを返す）
    TimetableExtractor.stub :extract, { success: true, data: @json } do
      # ダミーファイル（テストでは解析されないが、画像選択は必須のため使用）
      dummy_file = fixture_file_upload("public/icon.png")
      assert_difference "Stage.count", +2 do
        assert_difference "Performer.count", +3 do
          assert_difference "Performance.count", +3 do
            post event_timetables_path(@no_performance_event.event_key), params: {
              day_id: @no_performance_event_day.id,
              image: dummy_file
            }
          end
        end
      end
      assert_redirected_to show_timetable_path(@no_performance_event.event_key)
    end
  end
end
