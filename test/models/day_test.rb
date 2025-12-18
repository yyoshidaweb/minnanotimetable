require "test_helper"

class DayTest < ActiveSupport::TestCase
  def setup
    @performer = performers(:one)
    @stage = stages(:one)
    @day = days(:one)
  end

  # 開催日を削除するとday_idはnullになる
  test "destroying day nullifies performances.day_id" do
    day = @day
    performance = performances(:one)

    assert_equal day.id, performance.day_id

    day.destroy
    performance.reload

    assert_nil performance.day_id
  end
end
