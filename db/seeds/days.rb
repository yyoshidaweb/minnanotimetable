event = Event.find_by!(event_key: "one")

dates = [
  Date.today,
  Date.today + 1,
  Date.today + 2
]

dates.each do |date|
  Day.find_or_create_by!(
    event_id: event.id,
    date: date
  )
end
