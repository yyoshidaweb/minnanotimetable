module EventsHelper
  # イベント表示用のデータを整形して返す
  def prepare_event_timetable(event, selected_date: nil)
    days = event.days.order(:date)
    performers = event.performers.includes(:performer_name_tag)
    stages = event.stages.includes(:stage_name_tag)

    selected_date ||= days.first&.date

    performances = event.performances
                        .joins(:day)
                        .where(days: { date: selected_date })
                        .includes(
                          performer: :performer_name_tag,
                          stage: :stage_name_tag
                        )
                        .order(:start_time)
                        .map do |p|
      start_t = p.start_time
      duration = p.duration

      p.define_singleton_method(:start_h) { start_t.hour }
      p.define_singleton_method(:start_m) { start_t.min }
      p.define_singleton_method(:start_key) { start_t.hour * 60 + start_t.min }
      p.define_singleton_method(:formatted_start_time) { format("%02d:%02d", start_t.hour, start_t.min) }
      p.define_singleton_method(:duration_in_5_min_units) { duration / 5 }
      p.define_singleton_method(:show_start_time?) { duration >= 30 }

      line_clamp_class =
        case duration
        when 0..5 then "line-clamp-1"
        when 6..10 then "line-clamp-2"
        when 11..15 then "line-clamp-3"
        when 16..20 then "line-clamp-4"
        when 21..25 then "line-clamp-5"
        else "line-clamp-6"
        end
      p.define_singleton_method(:line_clamp_class) { line_clamp_class }
      p
    end

    performances_by_stage = performances.group_by(&:stage_id)

    earliest_time = performances.map(&:start_time).min&.hour || 0
    latest_end_time = performances.map(&:end_time).max&.hour || 23
    time_slots = (earliest_time..latest_end_time).flat_map { |h| (0..55).step(5).map { |m| [ h, m ] } }

    {
      days: days,
      performers: performers,
      stages: stages,
      selected_date: selected_date,
      performances: performances,
      performances_by_stage: performances_by_stage,
      time_slots: time_slots
    }
  end
end
