user_1 = User.find_by!(username: "one")

tag_1 = EventNameTag.find_by!(name: "Event1")
tag_2 = EventNameTag.find_by!(name: "Event2")

# イベント1
Event.find_or_create_by!(
  event_key: "one",
  user_id: user_1.id,
  event_name_tag_id: tag_1.id,
  ) do |e|
  e.description = "テスト用の音楽フェス。3日間開催、複数ステージあり。"
  e.is_published = true
end

# イベント2
Event.find_or_create_by!(
  event_key: "two",
  user_id: user_1.id,
  event_name_tag_id: tag_2.id,
  ) do |e|
  e.description = "テスト用の音楽フェス。3日間開催、複数ステージあり。"
  e.is_published = true
end
