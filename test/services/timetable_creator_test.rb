require "test_helper"

class TimetableCreatorTest < ActionDispatch::IntegrationTest
  setup do
    @no_performance_event = events(:no_performance_event)
    @no_performance_event_day = days(:no_performance_event_day)
    @json = JSON.parse(file_fixture("timetable_json.json").read)
    @timetable_json_without_stages = JSON.parse(file_fixture("timetable_json_without_stages.json").read)
    @timetable_json_without_performance = JSON.parse(file_fixture("timetable_json_without_performance.json").read)
  end

  # タイムテーブルJSONからStage、Performer、Performanceを作成でき、AI利用回数が増加する
  test "should create stages, performers, and performances from timetable json and increase AI usage count" do
    original_ai_timetable_count = @no_performance_event.user.ai_timetable_count
    assert_difference "Stage.count", +2 do
      assert_difference "Performer.count", +3 do
        assert_difference "Performance.count", +3 do
          TimetableCreator.create_from_json(
            json: @json,
            event: @no_performance_event,
            day: @no_performance_event_day
          )
        end
      end
    end
    assert_equal original_ai_timetable_count + 1, @no_performance_event.user.ai_timetable_count
  end

  # タイムテーブルJSONにstageが含まれていない場合はエラーを返し、AI利用回数は増加しない
  test "should return error if no stages in json and not increase AI usage count" do
    original_ai_timetable_count = @no_performance_event.user.ai_timetable_count
    assert_equal({ success: false, error: "タイムテーブルを認識できませんでした" },
      TimetableCreator.create_from_json(
        json: @timetable_json_without_stages,
        event: @no_performance_event,
        day: @no_performance_event_day
      )
    )
    assert_equal original_ai_timetable_count, @no_performance_event.user.ai_timetable_count
  end

  # タイムテーブルJSONにperformanceが含まれていない場合はエラーを返す
  test "should return error if no performances in json" do
    assert_equal({ success: false, error: "タイムテーブルを認識できませんでした" },
      TimetableCreator.create_from_json(
        json: @timetable_json_without_performance,
        event: @no_performance_event,
        day: @no_performance_event_day
      )
    )
  end
end
