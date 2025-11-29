# テストユーザー1
User.find_or_create_by!(email: "user1@example.com") do |u|
  u.name     = "User One"
  u.provider = "google_oauth2"
  u.uid      = "google-uid-12345"
  u.username = "abcd1234"
end

# テストユーザー2
User.find_or_create_by!(email: "user2@example.com") do |u|
  u.name     = "User Two"
  u.provider = "google_oauth2"
  u.uid      = "google-uid-67890"
  u.username = "efgh5678"
end
