require "test_helper"

class PerformancesControllerTest < ActionDispatch::IntegrationTest
  # Devise のテストヘルパーをインクルード
  include Devise::Test::IntegrationHelpers

  # 各テストの前に実行されるセットアップメソッド
  # fixtures に登録済みの event ラベルを利用
  setup do
    # Google 認証のテスト用ユーザーを作成
    @user = users(:one) # fixtures の user を利用
    # テスト用のログイン状態を再現
    sign_in @user
    @event = events(:one)
    @event_two = events(:two)
    @other_event = events(:four)
    @performance = performances(:one)
    @other_performance = performances(:five)
    @current_day = Date.current
  end

  # 出演情報作成ページ
  test "should get new" do
    get new_event_performance_url(@event.event_key)
    assert_response :success
  end

  # 他者の出演情報作成ページはアクセスできない
  test "should not get new of other user's event" do
    get new_event_performance_url(@other_event.event_key)
    assert_response :not_found
  end

  # 出演情報を作成し、作成後は保存した日付のdパラメータ付きでリダイレクトされる
  test "should create performance" do
    day = @event.days.first
    assert_difference("Performance.for_event(@event).count") do
      post event_performances_path(@event.event_key), params: {
        performance: {
          performer_id: @event.performers.first.id,
          day_id: day.id,
          stage_id: @event.stages.first.id,
          start_time_hour: "10",
          start_time_minute: "00",
          duration: 30
        }
      }
    end
    assert_redirected_to show_timetable_path(@event.event_key, d: day.date)
  end

  # 出演者名だけで出演情報を作成でき、日付を指定していないためdパラメータ無しでリダイレクトされる
  test "should create performance only with performer" do
    assert_difference("Performance.for_event(@event).count") do
      post event_performances_path(@event.event_key), params: {
        performance: {
          performer_id: @event.performers.first.id
        }
      }
    end
    assert_redirected_to show_timetable_path(@event.event_key)
  end

  # 出演者名が空文字の場合は作成できない
  test "should not create blank performance" do
    assert_no_difference("Performance.for_event(@event).count") do
      post event_performances_path(@event.event_key), params: {
        performance: {
          performer_id: ""
        }
      }
    end
    assert_response :unprocessable_entity
  end

  # 時刻が正しくないと出演情報を作成できない
  test "should not create performance with invalid time" do
    assert_no_difference("Performance.for_event(@event).count") do
      post event_performances_path(@event.event_key), params: {
        performance: {
          performer_id: @event.performers.first.id,
          day_id: @event.days.first.id,
          stage_id: @event.stages.first.id,
          start_time_hour: "10",
          start_time_minute: "",
          duration: "30"
        }
      }
    end
    assert_response :unprocessable_entity
  end

  # 出演情報編集ページ
  test "should get edit" do
    get edit_event_performance_url(@event.event_key, @performance)
    assert_response :success
  end

  # 他者の出演情報編集ページはアクセスできない
  test "should not get edit of other user's event" do
    get edit_event_performance_url(@other_event.event_key, @other_performance)
    assert_response :not_found
  end

  # 出演情報を出演者以外の全項目編集
  test "should update performance" do
    patch event_performance_path(@event.event_key, @performance), params: {
      performance: {
        day_id: @event.days.second.id,
        stage_id: @event.stages.second.id,
        start_time_hour: "11",
        start_time_minute: "10",
        duration: 15
      }
    }
    @performance.reload
    assert_redirected_to event_performer_url(@event.event_key, @performance.performer)
    assert_equal @event.days.second.id,       @performance.day_id
    assert_equal @event.stages.second.id,     @performance.stage_id
    assert_equal 11, @performance.start_time.hour
    assert_equal 10, @performance.start_time.min
    # 期待値
    expected = Time.zone.parse("11:25")
    assert_equal expected.hour, @performance.end_time.hour
    assert_equal expected.min, @performance.end_time.min
  end

  # 出演情報編集時にperformer_idを送信しても変更されない
  test "should not update performance with performer" do
    original_performer_id = @performance.performer_id
    patch event_performance_path(@event.event_key, @performance), params: {
      performance: {
        performer_id: @event.performers.second.id,
        day_id: @event.days.second.id,
        stage_id: @event.stages.second.id,
        start_time_hour: "11",
        start_time_minute: "10",
        duration: 15
      }
    }
    assert_redirected_to event_performer_url(@event.event_key, @performance.performer)
    @performance.reload
    # 編集前と編集後のperformer_idが変更されていないことを確認
    assert_equal @performance.performer_id, original_performer_id
  end

  # 時刻が正しくないと出演情報を編集できない
  test "should not update performance with invalid time" do
    patch event_performance_path(@event.event_key, @performance), params: {
      performance: {
        performer_id: @event.performers.first.id,
        day_id: @event.days.first.id,
        stage_id: @event.stages.first.id,
        start_time_hour: "10",
        start_time_minute: "",
        duration: 30
      }
    }
    assert_response :unprocessable_entity
  end

  # 出演情報削除
  test "should destroy performance" do
    assert_difference("Performance.for_event(@event).count", -1) do
      delete event_performance_path(@event.event_key, @performance)
    end
    assert_redirected_to event_performer_url(@event.event_key, @performance.performer)
  end

  # 他者の出演情報は削除できない
  test "should not destroy other user's performance" do
    assert_no_difference("Performance.for_event(@event).count", -1) do
      delete event_performance_path(@other_event.event_key, @other_performance)
    end
    assert_response :not_found
  end
end
