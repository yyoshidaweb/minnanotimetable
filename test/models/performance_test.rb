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

  test "is invalid without performer" do
    performance = Performance.new

    assert_not performance.valid?
    assert_includes performance.errors[:performer], "を入力してください"
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

  # 開始時刻が未設定の場合はdurationを計算しない
  test "does not calculate duration if start_time is missing" do
    performance = Performance.new(
      performer: @performer,
      end_time: Time.zone.parse("12:00")
    )
    performance.save!

    assert_nil performance.duration
  end
end
