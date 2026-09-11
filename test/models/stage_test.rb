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

  # 入場規制はデフォルトでオフ
  test "admission_restricted defaults to false" do
    assert_not @stage.admission_restricted?
  end

  # 入場規制フラグを更新できる
  test "updates admission_restricted" do
    assert @stage.update(admission_restricted: true)
    assert @stage.reload.admission_restricted?
  end

  # スキーマキャッシュが古いときは before_save で再読込してから保存する
  test "resets column information before save when admission_restricted is missing" do
    reset_called = false
    original_column_names = Stage.method(:column_names)
    original_reset = Stage.method(:reset_column_information)

    Stage.define_singleton_method(:column_names) do
      reset_called ? original_column_names.call : (original_column_names.call - [ "admission_restricted" ])
    end
    Stage.define_singleton_method(:reset_column_information) do
      reset_called = true
      original_reset.call
    end

    begin
      @stage.update!(admission_restricted: false)
      assert @stage.update(admission_restricted: true)
      assert reset_called
      assert @stage.reload.admission_restricted?
    ensure
      Stage.define_singleton_method(:column_names, original_column_names)
      Stage.define_singleton_method(:reset_column_information, original_reset)
      Stage.reset_column_information
    end
  end
end
