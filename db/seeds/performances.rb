event = Event.find_by!(event_key: "test-event-123")

days = Day.where(event_id: event.id).order(:date)
performers = Performer.where(event_id: event.id)
stages = Stage.where(event_id: event.id)

# サンプル: 各日 3公演
days.each_with_index do |day, i|
  performers.each_with_index do |performer, j|
    stage = stages[j % stages.count]

    start = Time.current.change(hour: 12 + j * 2, min: 0, sec: 0)
    end_t = start + 1.hour

    Performance.find_or_create_by!(
      day_id: day.id,
      performer_id: performer.id,
      stage_id: stage.id,
      start_time: start,
      end_time: end_t
    ) do |p|
      # 公演時間を分単位で保存
      p.duration = ((end_t - start) / 60).to_i
    end
  end
end
