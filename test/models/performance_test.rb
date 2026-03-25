require "test_helper"

class PerformanceTest < ActiveSupport::TestCase
  def setup
    @performer = performers(:one)
    @stage = stages(:one)
    @day = days(:one)
  end

  # 出演者以外は全てnilで保存可能
  test "is valid with performer only (time not set)" do
    performance = Performance.new(
      performer: @performer
    )

    assert performance.valid?
    assert_nil performance.start_time
    assert_nil performance.end_time
    assert_nil performance.duration
  end

  # start_time + duration で end_time が自動生成される
  test "calculates end_time from start_time and duration" do
    performance = Performance.new(
      performer: @performer,
      start_time: Time.zone.parse("10:00"),
      duration: 30
    )
    performance.save!
    # 期待値
    expected = Time.zone.parse("10:30")
    assert_equal expected.hour, performance.end_time.hour
    assert_equal expected.min, performance.end_time.min
  end

  # 出演者必須
  test "is invalid without performer" do
    performance = Performance.new

    assert_not performance.valid?
    assert_includes performance.errors[:performer], "を入力してください"
  end

  # durationがある場合はstart_time必須
  test "is invalid when duration is present but start_time is missing" do
    performance = Performance.new(
      performer: @performer,
      duration: 30
    )

    assert_not performance.valid?
    assert_includes performance.errors[:start_time], "を入力してください"
  end

  # start_timeがある場合はduration必須
  test "is invalid when start_time is present but duration is missing" do
    performance = Performance.new(
      performer: @performer,
      start_time: Time.zone.parse("12:00")
    )

    assert_not performance.valid?
    assert_includes performance.errors[:duration], "を入力してください"
  end

  # 終了時刻が開始時刻より早い場合はエラー
  test "is invalid when end_time is before start_time" do
    performance = Performance.new(
      performer: @performer,
      start_time: Time.zone.parse("12:00"),
      end_time: Time.zone.parse("11:00")
    )

    assert_not performance.valid?
    assert_includes performance.errors[:end_time], "は開始時刻より後にしてください"
  end
end
