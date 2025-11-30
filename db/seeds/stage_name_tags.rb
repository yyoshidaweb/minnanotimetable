[ "Main Stage", "Sub Stage" ].each do |name|
  StageNameTag.find_or_create_by!(name: name)
end
