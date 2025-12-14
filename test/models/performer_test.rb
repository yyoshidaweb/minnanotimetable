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
      assert_difference("Performance.count", -1) do
        performer.destroy
      end
    end
    # 削除されたことを確認
    assert_raises(ActiveRecord::RecordNotFound) do
      performance.reload
    end
  end
end
