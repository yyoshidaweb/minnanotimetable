module TimetablesHelper
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

  # タイムテーブル全体の開始時刻（正時のみ取得し、分は切り捨てる）
  def timetable_start_minute
    # 最初の1回だけ計算して、1リクエスト中は結果を使い回す
    @timetable_start_minute ||= begin
      earliest = @performances.min_by(&:start_time).start_time
      # タイムテーブル描画開始位置を正時にするため、minuteを切り捨てる
      earliest.hour * 60
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
    when ..15 then "line-clamp-1"
    when ..20 then "line-clamp-2"
    when ..35 then "line-clamp-3"
    when ..40 then "line-clamp-4"
    when ..50 then "line-clamp-5"
    else           "line-clamp-6"
    end
  end

  # 出演時間に応じた文字サイズクラスを返す
  def font_size_class_by_duration(duration)
    case duration
    when ..5 then "text-[10px]"
    else           "text-xs"
    end
  end

  # 出演時間が5分以下の場合のみ文字を少し上に移動する
  def translate_y_by_duration(duration)
    duration <= 5 ? "-translate-y-0.5" : ""
  end
end
