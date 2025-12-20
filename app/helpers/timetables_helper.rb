module TimetablesHelper
  # 出演情報ベースで表示時間帯（正時のみ）を決める
  def timetable_hours(performances)
    start_h = performances.min_by(&:start_time).start_time.hour
    end_h   = performances.max_by(&:end_time).end_time.hour
    (start_h..end_h).to_a
  end

  # performance がこの時間枠に入るか
  def performance_at(stage_performances, stage_id, hour, minute)
    return nil unless stage_performances[stage_id]

    slot_start = hour * 60 + minute
    slot_end   = slot_start + 30

    stage_performances[stage_id].find do |p|
      p.start_key >= slot_start && p.start_key < slot_end
    end
  end

  # 30分刻みの時刻スロットを生成
  def time_slots_for_timetable(performances)
    start_min =
      performances.min_by(&:start_time).start_time.hour * 60
    end_min =
      performances.max_by(&:end_time).end_time.hour * 60 + 30

    (start_min..end_min).step(30).map do |minute|
      [ minute / 60, minute % 60 ]
    end
  end
end
