event_names = (1..2).map { |i| "Event#{i}" }

event_names.each do |name|
  EventNameTag.find_or_create_by!(name: name)
end
