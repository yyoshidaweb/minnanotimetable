event = Event.find_by!(event_key: "test-event-123")

[
  { name: "Main Stage", desc: "屋外メインエリア", address: "東京都渋谷区" },
  { name: "Sub Stage", desc: "屋内ステージ", address: "東京都新宿区" }
].each do |data|
  tag = StageNameTag.find_by!(name: data[:name])

  Stage.find_or_create_by!(
    stage_name_tag_id: tag.id,
    event_id: event.id
  ) do |s|
    s.description = data[:desc]
    s.address = data[:address]
  end
end
