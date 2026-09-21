require "test_helper"

class PerformerTest < ActiveSupport::TestCase
  def setup
    @performer = performers(:one)
    @stage = stages(:one)
    @day = days(:one)
  end

  # 出演者を削除すると紐づいている出演情報も削除される
  test "should destroy performer" do
    performer = @performer
    performance = performances(:one)

    assert_equal performer.id, performance.performer_id

    assert_difference("Performer.count", -1) do
      assert_difference("Performance.count", -2) do
        performer.destroy
      end
    end
    # 削除されたことを確認
    assert_raises(ActiveRecord::RecordNotFound) do
      performance.reload
    end
  end

  # 出演情報は開催日と6時起点の開始時刻順
  test "performances are ordered by festival day and time" do
    overnight = Performance.create!(
      performer: @performer,
      day: @day,
      stage: stages(:two),
      start_time: Time.zone.parse("01:00"),
      duration: 30
    )
    evening = Performance.create!(
      performer: @performer,
      day: @day,
      stage: stages(:two),
      start_time: Time.zone.parse("22:00"),
      duration: 30
    )

    assert_operator @performer.performances.index(evening), :<, @performer.performances.index(overnight)
  end

  # 開催日が違う場合は、遅い日の早い時刻より先に並ぶ
  test "performances on an earlier day come before a later day" do
    later_day = Performance.create!(
      performer: @performer,
      day: days(:two),
      stage: stages(:two),
      start_time: Time.zone.parse("10:00"),
      duration: 30
    )
    earlier_day_overnight = Performance.create!(
      performer: @performer,
      day: @day,
      stage: stages(:two),
      start_time: Time.zone.parse("01:00"),
      duration: 30
    )

    ordered = @performer.performances.to_a
    assert_operator ordered.index(earlier_day_overnight), :<, ordered.index(later_day)
  end

  test "unset_field_labels returns 出演情報 when there are no performances" do
    performer = Performer.create!(
      event: events(:one),
      performer_name_tag: PerformerNameTag.create!(name: "バッジ確認出演者")
    )

    assert_equal [ "出演情報" ], performer.unset_field_labels
    assert performer.has_unset_items?
  end

  test "unset_field_labels returns missing fields from incomplete performances" do
    performer = Performer.create!(
      event: events(:one),
      performer_name_tag: PerformerNameTag.create!(name: "一部未設定出演者")
    )
    Performance.create!(performer: performer, day: @day)

    assert_equal %w[時刻 ステージ], performer.unset_field_labels
    assert performer.has_unset_items?
  end

  test "with_unset_items includes incomplete and empty performers only" do
    empty = Performer.create!(
      event: events(:one),
      performer_name_tag: PerformerNameTag.create!(name: "空出演者")
    )
    incomplete = Performer.create!(
      event: events(:one),
      performer_name_tag: PerformerNameTag.create!(name: "不完全出演者")
    )
    Performance.create!(performer: incomplete)
    complete = performers(:one)

    result = events(:one).performers.with_unset_items

    assert_includes result, empty
    assert_includes result, incomplete
    assert_not_includes result, complete
  end
end
