require "test_helper"

class EventTest < ActiveSupport::TestCase
  test "future_all excludes non-public events" do
    assert_not_includes Event.future_all, events(:unpublished)
    assert_not_includes Event.future_all, events(:unlisted)
  end

  test "past_all excludes non-public events" do
    assert_not_includes Event.past_all, events(:unpublished)
    assert_not_includes Event.past_all, events(:unlisted)
  end

  test "visibility enum values" do
    event = events(:one)
    assert event.visibility_public?

    event.visibility = :unlisted
    assert event.visibility_unlisted?

    event.visibility = :private
    assert event.visibility_private?
  end

  test "viewable_by_url returns true for public and unlisted" do
    assert events(:one).viewable_by_url?
    assert events(:unlisted).viewable_by_url?
    assert_not events(:unpublished).viewable_by_url?
  end

  test "search_indexable returns true only for public events" do
    assert events(:one).search_indexable?
    assert_not events(:unlisted).search_indexable?
    assert_not events(:unpublished).search_indexable?
  end

  test "recent_favorite_by excludes private events for other users" do
    favorites = Event.recent_favorite_by(users(:two))
    assert_not_includes favorites, events(:unpublished)
  end

  test "recent_favorite_by includes private events for owner" do
    favorites = Event.recent_favorite_by(users(:one))
    assert_includes favorites, events(:unpublished)
  end

  test "recent_favorite_by includes unlisted events" do
    favorites = Event.recent_favorite_by(users(:two))
    assert_includes favorites, events(:unlisted)
  end

  test "paginate_relation returns 20 per page and next_page" do
    user = users(:one)
    create_list_events(user, Event::PER_PAGE + 1)

    page1 = Event.paginate_relation(Event.recent_created_by(user), page: 1)
    assert_equal Event::PER_PAGE, page1[:events].size
    assert_equal 2, page1[:next_page]

    page2 = Event.paginate_relation(Event.recent_created_by(user), page: 2)
    assert_operator page2[:events].size, :>=, 1
    assert_nil page2[:next_page]
  end

  test "paginate_public_all paginates and sets section headings" do
    create_list_events(users(:one), Event::PER_PAGE + 5, day_date: Date.current + 40.days)

    page1 = Event.paginate_public_all(page: 1)
    assert_equal Event::PER_PAGE, page1[:events].size
    assert page1[:show_upcoming_heading]
    assert_equal 2, page1[:next_page]

    page2 = Event.paginate_public_all(page: 2)
    assert_operator page2[:events].size, :>, 0
    assert_not page2[:show_upcoming_heading]
  end

  private

  def create_list_events(user, count, day_date: nil)
    count.times do |i|
      tag = EventNameTag.create!(name: "model-paging-#{user.id}-#{i}-#{SecureRandom.hex(4)}")
      event = user.events.create!(
        event_key: "model-paging-#{user.id}-#{i}-#{SecureRandom.urlsafe_base64(4)}",
        event_name_tag: tag,
        description: "モデルページングテスト",
        visibility: :public
      )
      event.days.create!(date: day_date) if day_date
    end
  end
end
