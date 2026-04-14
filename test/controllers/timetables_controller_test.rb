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
    # ダミーファイル（テストでは解析されないが、画像選択は必須のため使用）
    @dummy_file = fixture_file_upload("public/icon.png")
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

  # AIタイムテーブル作成ページにアクセスできる
  test "should get new timetable page" do
    get new_event_timetable_path(@event.event_key)
    assert_response :success
  end

  # 他人のAIタイムテーブル作成ページにはアクセスできない
  test "should not get new timetable page for other users" do
    get new_event_timetable_path(@no_performance_event.event_key)
    assert_response :not_found
  end

  # AIタイムテーブル作成が成功する
  test "should create timetable with AI" do
    sign_out @user
    sign_in @user_two
    # TimetableExtractorをモック（APIは利用せず、常に固定JSONを返す）
    TimetableExtractor.stub :extract, { success: true, data: @json } do
      assert_difference "Stage.count", +2 do
        assert_difference "Performer.count", +3 do
          assert_difference "Performance.count", +3 do
            post event_timetables_path(@no_performance_event.event_key), params: {
              day_id: @no_performance_event_day.id,
              image: @dummy_file
            }
          end
        end
      end
      assert_redirected_to show_timetable_path(@no_performance_event.event_key, d: @no_performance_event_day.date)
    end
  end

  # 他人のAIタイムテーブル作成はできない
  test "should not create timetable with AI for other users" do
    # TimetableExtractorをモック（APIは利用せず、常に固定JSONを返す）
    TimetableExtractor.stub :extract, { success: true, data: @json } do
      post event_timetables_path(@no_performance_event.event_key), params: {
        day_id: @no_performance_event_day.id,
        image: @dummy_file
      }
      assert_response :not_found
    end
  end

  # AIタイムテーブル作成時にJSONパースエラーが発生した場合は作成できない
  test "should not create timetable with AI if JSON parse error occurs" do
    sign_out @user
    sign_in @user_two
    # TimetableExtractorをモック（APIは利用せず、常に失敗した結果だけを返す）
    TimetableExtractor.stub :extract, { success: false, error: "画像解析結果の読み込みに失敗しました" } do
      assert_no_difference "Stage.count" do
        assert_no_difference "Performer.count" do
          assert_no_difference "Performance.count" do
            post event_timetables_path(@no_performance_event.event_key), params: {
              day_id: @no_performance_event_day.id,
              image: @dummy_file
            }
          end
        end
      end
      assert_response :unprocessable_entity
      assert_match "画像解析結果の読み込みに失敗しました", response.body
    end
  end

  # AIタイムテーブル作成時に画像解析が失敗した場合は作成できない
  test "should not create timetable with AI if image parsing fails" do
    sign_out @user
    sign_in @user_two
    # TimetableExtractorをモック（APIは利用せず、常に失敗した結果だけを返す）
    TimetableExtractor.stub :extract, { success: false, error: "画像解析に失敗しました" } do
      post event_timetables_path(@no_performance_event.event_key), params: {
        day_id: @no_performance_event_day.id,
        image: @dummy_file
      }
      assert_response :unprocessable_entity
      assert_match "画像解析に失敗しました", response.body
    end
  end

  # AIタイムテーブル作成時に画像が選択されていない場合は作成できない
  test "should not create timetable with AI if no image is selected" do
    sign_out @user
    sign_in @user_two
    assert_no_difference "Stage.count" do
      assert_no_difference "Performer.count" do
        assert_no_difference "Performance.count" do
          post event_timetables_path(@no_performance_event.event_key), params: {
            day_id: @no_performance_event_day.id
          }
        end
      end
    end
    assert_response :unprocessable_entity
    assert_match "画像を選択してください", response.body
  end

  # AIタイムテーブル作成時に開催日が選択されていない場合は作成できない
  test "should not create timetable with AI if no day is selected" do
    sign_out @user
    sign_in @user_two
    assert_no_difference "Stage.count" do
      assert_no_difference "Performer.count" do
        assert_no_difference "Performance.count" do
          post event_timetables_path(@no_performance_event.event_key), params: {
            image: @dummy_file
          }
        end
      end
    end
    assert_response :unprocessable_entity
    assert_match "開催日を選択してください", response.body
  end
end
