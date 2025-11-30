performer_tags = [ "DJ Yoshi", "The Rails Band", "Frontend Girls" ]

performer_tags.each do |name|
  PerformerNameTag.find_or_create_by!(name: name)
end
