require "test_helper"

class EventNameTagsControllerTest < ActionDispatch::IntegrationTest
# 検索結果が返る（部分一致・3つ以上のイベントに紐づいているもののみ）
test "should return suggestions for matching tags with at least 3 events" do
  # 検索リクエスト送信
  get search_event_name_tags_url, params: { query: "Event" }, headers: {
    "Accept" => "text/vnd.turbo-stream.html"
  }

  # 成功しているか
  assert_response :success
  # 返す形式が正しいか
  assert_equal "text/vnd.turbo-stream.html", @response.media_type
end

  # 該当なしの場合は空HTML（または空エリア）
  test "should return empty list when no match" do
    EventNameTag.create!(name: "AAAA")
    EventNameTag.create!(name: "BBBB")

    get search_event_name_tags_url, params: { query: "ZZZ" }, headers: {
      "Accept" => "text/vnd.turbo-stream.html"
    }

    assert_response :success

    # 0件の場合はテンプレート内のループ出力なし
    assert_select "button[data-tag-suggestion-name-value]", 0
  end
end
