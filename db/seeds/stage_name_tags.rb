stage_names = (1..21).map { |i| "Stage#{i}" }

stage_names.each do |name|
  StageNameTag.find_or_create_by!(name: name)
end
