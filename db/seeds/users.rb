# テストユーザー1
User.find_or_create_by!(email: "user1@example.com") do |u|
  u.name     = "User1"
  u.description = "ユーザー1"
  u.provider = "google_oauth2"
  u.uid      = "google-uid-12345"
  u.username = "one"
end

# テストユーザー2
User.find_or_create_by!(email: "user2@example.com") do |u|
  u.name     = "User2"
  u.description = "ユーザー2"
  u.provider = "google_oauth2"
  u.uid      = "google-uid-67890"
  u.username = "two"
end
