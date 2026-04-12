require "test_helper"

class PerformanceTest < ActiveSupport::TestCase
  def setup
    @performer = performers(:one)
    @stage = stages(:one)
    @another_stage = stages(:two)
    @day = days(:one)
    @performance_for_overlaps = performances(:one)
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

  # 出演者必須（出演者以外の項目を全て選択済みの場合）
  test "is invalid without performer when other fields are present" do
    performance = Performance.new(
      day: @day,
      stage: @stage,
      start_time: @performance_for_overlaps.end_time,
      duration: 30
    )

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

  # durationが5以下の場合はエラー
  test "is invalid when duration is less than five" do
    performance = Performance.new(
      performer: @performer,
      start_time: Time.zone.parse("12:00"),
      duration: 0
    )

    assert_not performance.valid?
    assert_includes performance.errors[:duration], "は5以上で入力してください"
  end

  # 同じ日・同じステージで時間が重複する出演情報は作成できない
  test "is invalid when time overlaps on same day and stage" do
    performance = Performance.new(
      performer: @performer,
      day: @day,
      stage: @stage,
      start_time: @performance_for_overlaps.start_time + 10.minutes,
      duration: 30
    )

    assert_not performance.valid?
    assert_includes performance.errors[:base], "同じ時間帯に他の出演情報が存在します"
  end


  # 同じ日・同じステージでも時間が重複しなければ作成できる
  test "is valid when time does not overlap on same day and stage" do
    performance = Performance.new(
      performer: @performer,
      day: @day,
      stage: @stage,
      start_time: @performance_for_overlaps.end_time,
      duration: 30
    )

    assert performance.valid?
  end


  # ステージが違えば同じ時間でも作成できる
  test "is valid when stage is different" do
    performance = Performance.new(
      performer: @performer,
      day: @day,
      stage: @another_stage,
      start_time: @performance_for_overlaps.start_time,
      duration: 30
    )

    assert performance.valid?
  end


  # 未定（start_timeなし）の場合は重複チェックしない
  test "is valid when start_time is nil" do
    performance = Performance.new(
      performer: @performer,
      day: @day,
      stage: @stage,
      start_time: nil,
      duration: nil
    )

    assert performance.valid?
  end


  # 更新時は自分自身を重複として判定しない
  test "does not detect overlap with itself on update" do
    @performance_for_overlaps.duration = 30

    assert @performance_for_overlaps.valid?
  end
end
