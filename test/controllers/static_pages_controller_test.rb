require "test_helper"

class StaticPagesControllerTest < ActionDispatch::IntegrationTest
  test "terms page does not include website structured data" do
    get terms_path
    assert_response :success
    assert_select "script[type='application/ld+json']", count: 0
  end

  test "should get privacy" do
    get privacy_path
    assert_response :success
  end

  test "terms includes back link to root" do
    get terms_path
    assert_response :success
    assert_select "a[href=?][aria-label=?]", root_path, "トップへ戻る" do
      assert_select "span.material-symbols-outlined", text: "arrow_back"
      assert_select "span", text: "トップへ"
    end
  end

  test "privacy includes back link to root" do
    get privacy_path
    assert_response :success
    assert_select "a[href=?][aria-label=?]", root_path, "トップへ戻る" do
      assert_select "span.material-symbols-outlined", text: "arrow_back"
      assert_select "span", text: "トップへ"
    end
  end

  test "footer does not include all timetables link" do
    get terms_path
    assert_response :success
    assert_select "footer a[href=?]", events_path, count: 0
    assert_select "footer a[href=?]", terms_path, text: "利用規約"
    assert_select "footer a[href=?]", privacy_path, text: "プライバシーポリシー"
  end

  test "footer includes status page link" do
    get terms_path
    assert_response :success
    assert_select "a[href=?][target=_blank][rel='noopener noreferrer']",
                  "https://stats.uptimerobot.com/ZRof25OUD7",
                  text: "稼働状況"
  end
end
