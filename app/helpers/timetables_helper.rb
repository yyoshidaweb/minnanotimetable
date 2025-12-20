module TimetablesHelper
  # 出演情報ベースで表示時間帯（正時のみ）を決める
  def timetable_hours(performances)
    start_h = performances.min_by(&:start_time).start_time.hour
    end_h   = performances.max_by(&:end_time).end_time.hour
    (start_h..end_h).to_a
  end

  # 指定時間・ステージの出演情報を取得
  def performance_at(performances_by_stage, stage_id, hour)
    performances_by_stage[stage_id]&.find do |p|
      p.start_time.hour == hour
    end
  end
end
