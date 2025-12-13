require "test_helper"

class PerformerTest < ActiveSupport::TestCase
  def setup
    @performer = performers(:one)
    @stage = stages(:one)
    @day = days(:one)
  end

  # 出演情報と紐づいている出演者は削除できない
  test "should not destroy performer when performances exist" do
    performer = @performer
    performance = performances(:one)

    assert_equal performer.id, performance.performer_id

    assert_raises(ActiveRecord::DeleteRestrictionError) do
      performer.destroy
    end
    performance.reload

    # Performer が削除されていないこと
    assert Performer.exists?(performer.id)
  end
end
