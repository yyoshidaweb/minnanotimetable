require "test_helper"

class EventTest < ActiveSupport::TestCase
  test "future_all orders by nearest upcoming day not last day" do
    near = users(:developer).events.create!(
      event_key: "near-#{SecureRandom.urlsafe_base64(4)}",
      event_name_tag: EventNameTag.create!(name: "near-#{SecureRandom.hex(4)}"),
      description: "近い未来日を含む複数日",
      visibility: :public
    )
    near_day = near.days.create!(date: Date.current + 1.day)
    near.days.create!(date: Date.current + 30.days)
    add_timetable_ready_performance!(near, day: near_day)

    far = users(:developer).events.create!(
      event_key: "far-#{SecureRandom.urlsafe_base64(4)}",
      event_name_tag: EventNameTag.create!(name: "far-#{SecureRandom.hex(4)}"),
      description: "遠い未来日のみ",
      visibility: :public
    )
    far_day = far.days.create!(date: Date.current + 10.days)
    add_timetable_ready_performance!(far, day: far_day)

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

  # 開催日あり・描画可能な出演情報0件は「出演情報なし」へ
  test "without_timetable_ready_all includes public events with days but no ready performances" do
    event = events(:no_performance_event)
    assert_equal 0, event.performances.count
    assert event.days.any?
    assert_includes Event.without_timetable_ready_all, event
    assert_not_includes Event.future_all, event
    assert_not_includes Event.past_all, event
    assert_not_includes Event.undated_all, event
  end

  # 出演日・ステージ・時刻が欠けた出演情報だけでは future/past に入らない
  test "without_timetable_ready_all includes events with only incomplete performances" do
    user = users(:developer)
    event = user.events.create!(
      event_key: "incomplete-#{SecureRandom.urlsafe_base64(4)}",
      event_name_tag: EventNameTag.create!(name: "incomplete-#{SecureRandom.hex(4)}"),
      description: "未定だらけの出演のみ",
      visibility: :public
    )
    event.days.create!(date: Date.current + 3.days)
    performer = event.performers.create!(
      performer_name_tag: PerformerNameTag.create!(name: "incomplete-performer-#{SecureRandom.hex(4)}")
    )
    Performance.create!(performer: performer) # day/stage/time すべて未定

    assert_includes Event.without_timetable_ready_all, event
    assert_not_includes Event.future_all, event
  end

  # 開催日未定の公開イベントは undated_all にまとめ、他セクションには入れない
  test "undated_all includes only public events without days" do
    user = users(:developer)
    public_empty = user.events.create!(
      event_key: "empty-public-#{SecureRandom.urlsafe_base64(4)}",
      event_name_tag: EventNameTag.create!(name: "empty-public-#{SecureRandom.hex(4)}"),
      description: "開催日なし公開",
      visibility: :public
    )
    unlisted_empty = user.events.create!(
      event_key: "empty-unlisted-#{SecureRandom.urlsafe_base64(4)}",
      event_name_tag: EventNameTag.create!(name: "empty-unlisted-#{SecureRandom.hex(4)}"),
      description: "開催日なし限定公開",
      visibility: :unlisted
    )
    private_empty = user.events.create!(
      event_key: "empty-private-#{SecureRandom.urlsafe_base64(4)}",
      event_name_tag: EventNameTag.create!(name: "empty-private-#{SecureRandom.hex(4)}"),
      description: "開催日なし非公開",
      visibility: :private
    )

    undated = Event.undated_all.to_a
    assert_includes undated, public_empty
    assert_not_includes undated, unlisted_empty
    assert_not_includes undated, private_empty
    assert_not_includes Event.future_all, public_empty
    assert_not_includes Event.past_all, public_empty
    assert_not_includes Event.without_timetable_ready_all, public_empty
  end

  test "paginate_public_all places without_timetable_ready after past" do
    create_list_events(users(:one), 1, day_date: Date.current - 5.days, with_ready_performance: true)
    create_list_events(users(:one), 1, day_date: Date.current + 2.days) # 出演情報なし

    page = 1
    result = nil
    100.times do
      result = Event.paginate_public_all(page: page)
      break if result[:without_timetable_ready_index] &&
        result[:without_timetable_ready_index] < result[:events].size
      break unless result[:next_page]

      page = result[:next_page]
    end

    assert result[:without_timetable_ready_index],
           "without_timetable_ready_index should be present"
    empty_event = result[:events][result[:without_timetable_ready_index]]
    assert empty_event.days.any?
    assert_not empty_event.performances.timetable_ready.exists?

    if result[:without_timetable_ready_index].positive?
      previous = result[:events][result[:without_timetable_ready_index] - 1]
      assert previous.performances.merge(Performance.timetable_ready).exists?
    end
  end

  test "paginate_public_all places undated events after without_timetable_ready" do
    create_list_events(users(:one), 1, day_date: Date.current - 5.days) # 出演情報なし
    create_list_events(users(:one), 1) # 開催日未定

    page = 1
    result = nil
    100.times do
      result = Event.paginate_public_all(page: page)
      break if result[:undated_index] && result[:undated_index] < result[:events].size
      break unless result[:next_page]

      page = result[:next_page]
    end

    assert result[:undated_index], "undated_index should be present on the page with undated events"
    undated_event = result[:events][result[:undated_index]]
    assert_empty undated_event.days

    if result[:undated_index].positive?
      previous = result[:events][result[:undated_index] - 1]
      assert previous.days.any?
    end
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
    create_list_events(users(:one), 1, day_date: Date.current - 7.days, with_ready_performance: true)

    page1 = Event.paginate_public_all(page: 1)
    assert_not page1[:show_upcoming_heading]
    assert_equal 0, page1[:past_index]
  end

  test "paginate_public_all paginates and sets section headings" do
    create_list_events(
      users(:one),
      Event::PER_PAGE + 5,
      day_date: Date.current + 40.days,
      with_ready_performance: true
    )

    page1 = Event.paginate_public_all(page: 1)
    assert_equal Event::PER_PAGE, page1[:events].size
    assert page1[:show_upcoming_heading]
    assert_equal 2, page1[:next_page]

    page2 = Event.paginate_public_all(page: 2)
    assert_operator page2[:events].size, :>, 0
    assert_not page2[:show_upcoming_heading]
  end

  test "paginate_public_all sets past_index at future/past boundary" do
    create_list_events(
      users(:one),
      Event::PER_PAGE,
      day_date: Date.current - 10.days,
      with_ready_performance: true
    )

    page = 1
    result = nil
    100.times do
      result = Event.paginate_public_all(page: page)
      # page 1 で未来のみのとき past_index は nil のため、過去が載るページを探す
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
    if (future_count % Event::PER_PAGE).zero?
      create_list_events(
        users(:one), 1,
        day_date: Date.current + 60.days,
        with_ready_performance: true
      )
    end
    create_list_events(
      users(:one), 1,
      day_date: Date.current - 20.days,
      with_ready_performance: true
    )

    future_count = Event.future_all.unscope(:includes, :order).count.size
    boundary_page = (future_count / Event::PER_PAGE) + 1
    result = Event.paginate_public_all(page: boundary_page)

    assert result[:past_index].positive?
    assert_operator result[:events].size, :>, result[:past_index]
    assert result[:events][result[:past_index] - 1].days.maximum(:date) >= Date.current
    assert result[:events][result[:past_index]].days.maximum(:date) < Date.current
  end

  private

  def create_list_events(user, count, day_date: nil, with_ready_performance: false)
    count.times do |i|
      tag = EventNameTag.create!(name: "model-paging-#{user.id}-#{i}-#{SecureRandom.hex(4)}")
      event = user.events.create!(
        event_key: "model-paging-#{user.id}-#{i}-#{SecureRandom.urlsafe_base64(4)}",
        event_name_tag: tag,
        description: "モデルページングテスト",
        visibility: :public
      )
      next unless day_date

      day = event.days.create!(date: day_date)
      add_timetable_ready_performance!(event, day: day) if with_ready_performance
    end
  end

  # タイムテーブル描画可能な出演情報を1件追加する
  def add_timetable_ready_performance!(event, day:)
    stage = event.stages.create!(
      stage_name_tag: StageNameTag.create!(name: "stage-#{SecureRandom.hex(4)}")
    )
    performer = event.performers.create!(
      performer_name_tag: PerformerNameTag.create!(name: "performer-#{SecureRandom.hex(4)}")
    )
    Performance.create!(
      performer: performer,
      day: day,
      stage: stage,
      start_time: "12:00",
      duration: 60
    )
  end
end
