performer_names = (1..101).map { |i| "Performer#{i}" }

performer_names.each do |name|
  PerformerNameTag.find_or_create_by!(name: name)
end
