require "test_helper"

class EventTest < ActiveSupport::TestCase
  test "future_all orders by nearest upcoming day not last day" do
    near = users(:developer).events.create!(
      event_key: "near-#{SecureRandom.urlsafe_base64(4)}",
      event_name_tag: EventNameTag.create!(name: "near-#{SecureRandom.hex(4)}"),
      description: "近い未来日を含む複数日",
      visibility: :public
    )
    near.days.create!(date: Date.current + 1.day)
    near.days.create!(date: Date.current + 30.days)

    far = users(:developer).events.create!(
      event_key: "far-#{SecureRandom.urlsafe_base64(4)}",
      event_name_tag: EventNameTag.create!(name: "far-#{SecureRandom.hex(4)}"),
      description: "遠い未来日のみ",
      visibility: :public
    )
    far.days.create!(date: Date.current + 10.days)

    futures = Event.future_all.to_a
    assert_operator futures.index(near), :<, futures.index(far)
  end

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

  test "paginate_relation returns PER_PAGE items and next_page" do
    user = users(:developer)
    create_list_events(user, Event::PER_PAGE + 1)

    page1 = Event.paginate_relation(Event.recent_created_by(user), page: 1)
    assert_equal Event::PER_PAGE, page1[:events].size
    assert_equal 2, page1[:next_page]

    page2 = Event.paginate_relation(Event.recent_created_by(user), page: 2)
    assert_equal 1, page2[:events].size
    assert_nil page2[:next_page]
  end

  test "paginate_relation treats invalid page as page 1" do
    user = users(:developer)
    create_list_events(user, 1)

    result = Event.paginate_relation(Event.recent_created_by(user), page: 0)
    assert_equal 1, result[:page]
    assert_equal 1, result[:events].size
  end

  test "paginate_public_all hides upcoming heading when there are no future events" do
    Event.future_all.find_each do |event|
      event.days.order(:id).each_with_index do |day, index|
        day.update!(date: Date.current - 30.days - index.days)
      end
    end
    create_list_events(users(:one), 1, day_date: Date.current - 7.days)

    page1 = Event.paginate_public_all(page: 1)
    assert_not page1[:show_upcoming_heading]
    assert_equal 0, page1[:past_index]
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

  test "paginate_public_all sets past_index at future/past boundary" do
    create_list_events(users(:one), Event::PER_PAGE, day_date: Date.current - 10.days)

    page = 1
    result = nil
    100.times do
      result = Event.paginate_public_all(page: page)
      # page 1 で未来のみのとき past_index は events.size（見出し用）になり得るため除外する
      break if result[:past_index] && result[:past_index] < result[:events].size
      break unless result[:next_page]

      page = result[:next_page]
    end

    assert result[:past_index], "past_index should be present on the page that includes past events"
    assert_operator result[:past_index], :<, result[:events].size
    idx = result[:past_index]
    past_event = result[:events][idx]
    assert past_event.days.maximum(:date) < Date.current

    if idx.positive?
      future_event = result[:events][idx - 1]
      assert future_event.days.maximum(:date) >= Date.current
    else
      assert_not result[:show_upcoming_heading]
    end
  end

  test "paginate_public_all fills remaining slots from past on the same page" do
    future_count = Event.future_all.unscope(:includes, :order).count.size
    # 最終の未来ページに余りが出るよう、割り切れる場合は未来を1件足す
    create_list_events(users(:one), 1, day_date: Date.current + 60.days) if (future_count % Event::PER_PAGE).zero?
    create_list_events(users(:one), 1, day_date: Date.current - 20.days)

    future_count = Event.future_all.unscope(:includes, :order).count.size
    boundary_page = (future_count / Event::PER_PAGE) + 1
    result = Event.paginate_public_all(page: boundary_page)

    assert result[:past_index].positive?
    assert_operator result[:events].size, :>, result[:past_index]
    assert result[:events][result[:past_index] - 1].days.maximum(:date) >= Date.current
    assert result[:events][result[:past_index]].days.maximum(:date) < Date.current
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
