require "application_system_test_case"

class TimetableModalEditTest < ApplicationSystemTestCase
  include Warden::Test::Helpers

  setup do
    Warden.test_mode!
    @user = users(:one)
    @event = events(:one)
    @performer = performers(:one)
    @stage = stages(:one)
    login_as @user, scope: :user
  end

  teardown do
    Warden.test_reset!
  end

  test "タイムテーブルの出演者モーダルから編集フォームへ差し替えられる" do
    visit show_timetable_path(@event.event_key)

    assert_text @performer.display_name
    find("a[data-turbo-frame='modal']", text: @performer.display_name, match: :first).click

    within "#modal" do
      assert_text @performer.display_name
      find("a[href='#{edit_event_performer_path(@event.event_key, @performer)}'][data-action='click->modal#navigate']").click
    end

    assert_current_path show_timetable_path(@event.event_key)

    within "#modal" do
      assert_button "更新"
      assert_no_link "詳細→"
    end
  end

  test "タイムテーブルのステージモーダルから編集フォームへ差し替えられる" do
    visit show_timetable_path(@event.event_key)

    find("a.stage-header-col[data-turbo-frame='modal']", text: @stage.display_name).click

    within "#modal" do
      assert_text @stage.display_name
      find("a[href='#{edit_event_stage_path(@event.event_key, @stage)}'][data-action='click->modal#navigate']").click
    end

    assert_current_path show_timetable_path(@event.event_key)

    within "#modal" do
      assert_button "更新"
    end
  end

  test "モーダルから出演者名を更新するとタイムテーブルに反映される" do
    new_name = "モーダル更新後の出演者"
    visit show_timetable_path(@event.event_key)

    assert_text @performer.display_name
    find("a[data-turbo-frame='modal']", text: @performer.display_name, match: :first).click

    within "#modal" do
      find("a[href='#{edit_event_performer_path(@event.event_key, @performer)}'][data-action='click->modal#navigate']").click
      fill_in "performer[performer_name_tag_attributes][name]", with: new_name
      click_on "更新"
    end

    assert_current_path show_timetable_path(@event.event_key)
    assert_text new_name
    assert_no_button "更新"
  end

  test "モーダルからステージ名を更新するとタイムテーブルに反映される" do
    new_name = "モーダル更新後のステージ"
    visit show_timetable_path(@event.event_key)

    find("a.stage-header-col[data-turbo-frame='modal']", text: @stage.display_name).click

    within "#modal" do
      find("a[href='#{edit_event_stage_path(@event.event_key, @stage)}'][data-action='click->modal#navigate']").click
      fill_in "stage[stage_name_tag_attributes][name]", with: new_name
      click_on "更新"
    end

    assert_current_path show_timetable_path(@event.event_key)
    assert_text new_name
    assert_no_button "更新"
  end

  test "モーダルから出演者名が空だとエラーがモーダル内に表示される" do
    visit show_timetable_path(@event.event_key)

    find("a[data-turbo-frame='modal']", text: @performer.display_name, match: :first).click

    within "#modal" do
      find("a[href='#{edit_event_performer_path(@event.event_key, @performer)}'][data-action='click->modal#navigate']").click
      fill_in "performer[performer_name_tag_attributes][name]", with: ""
      click_on "更新"
    end

    assert_current_path show_timetable_path(@event.event_key)
    within "#modal" do
      assert_text "出演者名を入力してください"
      assert_button "更新"
    end
  end

  test "モーダルからステージ名が空だとエラーがモーダル内に表示される" do
    visit show_timetable_path(@event.event_key)

    find("a.stage-header-col[data-turbo-frame='modal']", text: @stage.display_name).click

    within "#modal" do
      find("a[href='#{edit_event_stage_path(@event.event_key, @stage)}'][data-action='click->modal#navigate']").click
      fill_in "stage[stage_name_tag_attributes][name]", with: ""
      click_on "更新"
    end

    assert_current_path show_timetable_path(@event.event_key)
    within "#modal" do
      assert_text "ステージ名を入力してください"
      assert_button "更新"
    end
  end

  test "モーダルから出演情報の時刻が不正だとエラーがモーダル内に表示される" do
    performance = @performer.performances.first
    visit show_timetable_path(@event.event_key)

    find("a[data-turbo-frame='modal']", text: @performer.display_name, match: :first).click

    within "#modal" do
      find("a[href='#{edit_event_performance_path(@event.event_key, performance)}'][data-action='click->modal#navigate']").click
      select "10", from: "performance_start_time_hour"
      select "未定", from: "performance_start_time_minute"
      click_on "更新"
    end

    assert_current_path show_timetable_path(@event.event_key)
    within "#modal" do
      assert_button "更新"
      assert_text "を正しく指定するか、未定のままにしてください"
    end
  end
end
