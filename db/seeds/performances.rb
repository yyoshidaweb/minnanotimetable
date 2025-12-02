event = Event.find_by!(event_key: "one")

days = Day.where(event_id: event.id).order(:date) # 1日目, 2日目, 3日目
performers = Performer.where(event_id: event.id).order(:id)
stages = Stage.where(event_id: event.id)

return if stages.empty?

performers.each_with_index do |performer, j|
  # 出演日をグループごとに固定
  day = case j
  when 0..49
    days[0] # Performer1~50 → 1日目
  when 50..74
    days[1] # Performer51~75 → 2日目
  else
    days[2] # Performer76~100 → 3日目
  end

  # ステージを循環で割り当て
  stage = stages[j % stages.count]

  # 開始時間は12:00を基準に +2時間ずつずらす
  hour = (12 + j * 2) % 24
  minute = 0

  start_dt = Time.zone.local(day.date.year, day.date.month, day.date.day, hour, minute, 0)

  # duration は 5〜60分の範囲で5分刻みランダム
  duration_min = rand(1..12) * 5 # 1*5=5分, 12*5=60分

  end_dt = start_dt + duration_min.minutes

  start_time_str = start_dt.strftime("%H:%M:%S")
  end_time_str   = end_dt.strftime("%H:%M:%S")

  Performance.find_or_create_by!(
    day_id: day.id,
    performer_id: performer.id,
    stage_id: stage.id,
    start_time: start_time_str
  ) do |p|
    p.end_time   = end_time_str
    p.duration   = duration_min
    p.created_at = Time.current
    p.updated_at = Time.current
  end
end
