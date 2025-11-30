user = User.first

tag = EventNameTag.find_by!(name: "みんなの音楽フェス")

Event.find_or_create_by!(
  event_key: "test-event-123",
  user_id: user.id,
  event_name_tag_id: tag.id
) do |event|
  event.description = "テスト用の音楽フェス。3日間開催、複数ステージあり。"
  event.is_published = true
end
