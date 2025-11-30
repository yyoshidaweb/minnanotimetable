event_names = [
  "みんなの音楽フェス",
  "サンプルロックフェス",
  "テックカンファレンス2025"
]

event_names.each do |name|
  EventNameTag.find_or_create_by!(name: name)
end
