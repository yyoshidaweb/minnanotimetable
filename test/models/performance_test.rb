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

  test "incomplete? and missing_field_labels for unset fields" do
    performance = Performance.create!(performer: @performer)

    assert performance.incomplete?
    assert_equal %w[出演日 時刻 ステージ], performance.missing_field_labels
    assert_includes Performance.incomplete, performance
  end

  test "timetable ready performance is not incomplete" do
    performance = performances(:one)

    assert_not performance.incomplete?
    assert_empty performance.missing_field_labels
    assert_not_includes Performance.incomplete, performance
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

  # durationが120の場合は有効
  test "is valid when duration is 120" do
    performance = Performance.new(
      performer: @performer,
      start_time: Time.zone.parse("12:00"),
      duration: 120
    )

    assert performance.valid?
  end

  # durationが120より大きい場合はエラー
  test "is invalid when duration is greater than 120" do
    performance = Performance.new(
      performer: @performer,
      start_time: Time.zone.parse("12:00"),
      duration: 121
    )

    assert_not performance.valid?
    assert_includes performance.errors[:duration], "は120以下で入力してください"
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

  # 同じ開催日では22:00のあとに01:00が並ぶ
  test "orders 01:00 after 22:00 on the same day" do
    evening = create_timed_performance("22:00", duration: 30)
    overnight = create_timed_performance("01:00", duration: 30)

    ordered = @performer.performances.ordered_for_performer_detail.to_a
    assert_operator ordered.index(evening), :<, ordered.index(overnight)

    timetable_ordered = Performance.timetable_ready_for_event_on_date(@performer.event, @day.date).to_a
    assert_operator timetable_ordered.index(evening), :<, timetable_ordered.index(overnight)
  end

  # 日付境界の6:00は5:00より前に並ぶ
  test "orders 05:00 after 06:00 on the same day" do
    six = create_timed_performance("06:00", duration: 30)
    five = create_timed_performance("05:00", duration: 30)

    ordered = @performer.performances.ordered_for_performer_detail.to_a
    assert_operator ordered.index(six), :<, ordered.index(five)
  end

  # 昼間の出演は従来どおり開始時刻順
  test "keeps daytime performances in clock order" do
    ordered = @performer.performances.ordered_for_performer_detail.to_a
    assert_equal [ performances(:one), performances(:one_second) ], ordered
  end

  # 0時をまたぐ出演は深夜帯の重複を検出する
  test "is invalid when overnight performance overlaps after midnight" do
    create_timed_performance("23:00", duration: 120, stage: @another_stage)
    overlapping = Performance.new(
      performer: performers(:two),
      day: @day,
      stage: @another_stage,
      start_time: Time.zone.parse("00:30"),
      duration: 30
    )

    assert_not overlapping.valid?
    assert_includes overlapping.errors[:base], "同じ時間帯に他の出演情報が存在します"
  end

  # 0時をまたぐ出演でも、前の時間帯と接していなければ作成できる
  test "is valid when overnight performance does not overlap evening slot" do
    create_timed_performance("23:00", duration: 120, stage: @another_stage)
    performance = Performance.new(
      performer: performers(:two),
      day: @day,
      stage: @another_stage,
      start_time: Time.zone.parse("22:00"),
      duration: 60
    )

    assert performance.valid?
  end

  # 0時過ぎの開始時刻は24時台で表示する
  test "formats overnight start time with hour 24 or later" do
    performance = create_timed_performance("01:30", duration: 30)

    assert_equal "25:30", performance.formatted_start_time
  end

  private
    def create_timed_performance(start_hm, duration:, stage: @stage, performer: @performer, day: @day)
      Performance.create!(
        performer: performer,
        stage: stage,
        day: day,
        start_time: Time.zone.parse(start_hm),
        duration: duration
      )
    end
end
