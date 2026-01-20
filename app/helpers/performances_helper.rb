module PerformancesHelper
  # 5分刻みの時刻スロットを生成
  def time_select_options(hour_step: 1, minute_step: 5, start_hour: 0, end_hour: 24)
    {
      hours: (start_hour...end_hour).step(hour_step).map { |h| [ format("%02d", h), h ] },
      minutes: (0...60).step(minute_step).map { |m| [ format("%02d", m), m ] }
    }
  end

  # タイムテーブル全体の高さを rem で返す（1時間単位）
  def timetable_height_rem(performances)
    start_hour = performances.min_by(&:start_time).start_time.hour
    end_time   = performances.max_by(&:end_time).end_time
    # 終了時刻は「次の時間」に切り上げ
    end_hour = end_time.min.zero? ? end_time.hour : end_time.hour + 1
    total_hours = end_hour - start_hour
    rem_per_hour = 6.0
    total_hours * rem_per_hour
  end

  # タイムテーブル全体の開始時刻（分）
  def timetable_start_minute
    # 最初の1回だけ計算して、1リクエスト中は結果を使い回す
    @timetable_start_minute ||= begin
      earliest = @performances.min_by(&:start_time).start_time
      earliest.hour * 60 + earliest.min
    end
  end

  # performance の開始位置の top を rem で返す
  def performance_top_rem(performance)
  timetable_start_min = timetable_start_minute
  start_min = performance.start_time.hour * 60 + performance.start_time.min
  diff_min  = start_min - timetable_start_min
  rem_per_hour = 6.0
  rem_per_min  = rem_per_hour / 60.0
  diff_min * rem_per_min
  end

  # タイムテーブル用の時刻スロット配列を生成
  def time_slots_for_timetable(performances)
    start_time = performances.min_by(&:start_time).start_time
    end_time   = performances.max_by(&:end_time).end_time
    start_hour = start_time.hour
    # 終了時刻が00分なら、その時間は表示しない
    last_hour =
      if end_time.min.zero?
        end_time.hour - 1
      else
        end_time.hour
      end
    (start_hour..last_hour).to_a
  end

  # performance の高さを rem で返す
  def performance_height_rem(performance)
    rem_per_hour = 6.0
    rem_per_min  = rem_per_hour / 60.0
    duration_min = performance.duration
    duration_min * rem_per_min
  end

  # 出演時間に応じた line-clamp クラスを返す
  def line_clamp_class_by_duration(duration)
    case duration
    when ..5  then "line-clamp-1"
    when ..10 then "line-clamp-1"
    when ..15 then "line-clamp-1"
    when ..20 then "line-clamp-2"
    when ..25 then "line-clamp-3"
    when ..30 then "line-clamp-3"
    when ..35 then "line-clamp-3"
    when ..40 then "line-clamp-4"
    when ..45 then "line-clamp-5"
    when ..50 then "line-clamp-5"
    else           "line-clamp-6"
    end
  end
end
