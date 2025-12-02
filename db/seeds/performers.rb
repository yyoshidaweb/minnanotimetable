event = Event.find_by!(event_key: "one")

# PerformerNameTag を 1〜100 取得して配列化
tags = (1..100).map { |i| PerformerNameTag.find_by!(name: "Performer#{i}") }

tags.each_with_index do |tag, i|
  Performer.find_or_create_by!(
    performer_name_tag_id: tag.id,
    event_id: event.id
  ) do |p|
    p.description = "出演者#{i + 1}の説明"
    p.website_url = "https://test.example.com"
  end
end
