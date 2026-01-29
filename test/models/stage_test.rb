require "test_helper"

class StageTest < ActiveSupport::TestCase
  def setup
    @event = events(:one)
    @performer = performers(:one)
    @stage = stages(:one)
    @day = days(:one)
  end

  # ステージを削除するとstage_idはnullになる
  test "destroying stage nullifies performances.stage_id" do
    stage = @stage
    performance = performances(:one)

    assert_equal stage.id, performance.stage_id

    stage.destroy
    performance.reload

    assert_nil performance.stage_id
  end

  # ステージ作成時にpositionが自動設定される
  test "assigns position on creation" do
    max_position = @event.stages.order(:position).last.position
    new_stage = Stage.new(
      event: @event,
      stage_name_tag: stage_name_tags(:three)
    )
    new_stage.save!
    assert_equal max_position + 1, new_stage.position
  end
end
