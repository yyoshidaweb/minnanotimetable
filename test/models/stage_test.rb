require "test_helper"

class StageTest < ActiveSupport::TestCase
  def setup
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
end
