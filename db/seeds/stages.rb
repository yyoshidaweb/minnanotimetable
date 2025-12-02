event = Event.find_by!(event_key: "one")

# StageNameTag を 1〜20 取得して配列化
tags = (1..20).map { |i| StageNameTag.find_by!(name: "Stage#{i}") }

tags.each_with_index do |tag, i|
  Stage.find_or_create_by!(
    stage_name_tag_id: tag.id,
    event_id: event.id
  ) do |s|
    s.description = "ステージ#{i + 1}の説明"
    s.address = "テスト県テスト市テスト町1-1-1"
  end
end
