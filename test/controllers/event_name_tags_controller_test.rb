require "test_helper"

class EventNameTagsControllerTest < ActionDispatch::IntegrationTest
  # 検索結果が返る（部分一致・5件まで）
  test "should return suggestions for matching tags" do
    # 事前に6件作る（limit 5 をテスト）
    6.times do |i|
      EventNameTag.create!(name: "フェス#{i}")
    end

    get search_event_name_tags_url, params: { query: "フェス" }, headers: {
      "Accept" => "text/vnd.turbo-stream.html"
    }

    assert_response :success   # 200 が返っているか

    # turbo-stream 形式か？
    assert_equal "text/vnd.turbo-stream.html", @response.media_type

    # 返却 HTML に 5件分のボタンがあるか（limit 5）
    assert_select "button[data-tag-suggestion-name-value]", 5
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
