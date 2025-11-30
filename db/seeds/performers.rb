event = Event.find_by!(event_key: "test-event-123")

[
  { name: "DJ Yoshi", desc: "ハウス系 DJ", url: "https://example.com/yoshi" },
  { name: "The Rails Band", desc: "Rubyist ロックバンド", url: "https://example.com/railsband" },
  { name: "Frontend Girls", desc: "UI/UX 系ガールズユニット", url: "https://example.com/fegirls" }
].each do |data|
  tag = PerformerNameTag.find_by!(name: data[:name])

  Performer.find_or_create_by!(
    performer_name_tag_id: tag.id,
    event_id: event.id
  ) do |p|
    p.description = data[:desc]
    p.website_url = data[:url]
  end
end
