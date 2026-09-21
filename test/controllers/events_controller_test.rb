require "test_helper"

class EventsControllerTest < ActionDispatch::IntegrationTest
  # Devise のテストヘルパーをインクルード
  include Devise::Test::IntegrationHelpers

  # 各テストの前に実行されるセットアップメソッド
  # fixtures に登録済みの event ラベルを利用
  setup do
    # Google 認証のテスト用ユーザーを作成
    @user = users(:one) # fixtures の user を利用
    # テスト用のログイン状態を再現
    sign_in @user
    @event = events(:one)
    @other_event = events(:four)
  end

  # 未ログインでもイベント詳細も表示できる
  test "should show event with logout" do
    sign_out @user
    get event_url(@other_event.event_key)
    assert_response :success
  end

  # 概要タブには戻るボタンを付けない
  test "show does not include back link" do
    get event_url(@event.event_key)
    assert_response :success
    assert_select "a[aria-label$=戻る]", count: 0
  end

  # 編集ページには概要への戻るボタンがある
  test "edit includes back link to event show" do
    get edit_event_url(@event.event_key)
    assert_response :success
    assert_select "a[href=?][aria-label=?]", event_path(@event.event_key), "概要へ戻る" do
      assert_select "span.material-symbols-outlined", text: "arrow_back"
      assert_select "span", text: "概要"
    end
  end

  # 一覧ページにはトップへの戻るボタンがある
  test "index includes back link to root" do
    get events_path
    assert_response :success
    assert_select "a[href=?][aria-label=?]", root_path, "トップへ戻る" do
      assert_select "span.material-symbols-outlined", text: "arrow_back"
      assert_select "span", text: "トップ"
    end
  end


  test "should not show unpublished event with logout" do
    sign_out @user
    get event_url(events(:unpublished).event_key)
    assert_response :not_found
  end

  test "should show unlisted event with logout" do
    sign_out @user
    get event_url(events(:unlisted).event_key)
    assert_response :success
  end

  test "should show link icon on unlisted event detail" do
    sign_out @user
    get event_url(events(:unlisted).event_key)
    assert_response :success
    assert_select "span.material-symbols-outlined", text: "link"
    assert_select "span.material-symbols-outlined", text: "lock", count: 0
  end

  test "should not show unpublished event by other user" do
    sign_out @user
    sign_in users(:two)
    get event_url(events(:unpublished).event_key)
    assert_response :not_found
  end

  # 他者が作成したイベント詳細も表示できる
  test "should show event by other user" do
    get event_url(@other_event.event_key)
    assert_response :success
  end

  test "should show lock icon on unpublished event detail for owner" do
    unpublished_event = events(:unpublished)
    get event_url(unpublished_event.event_key)
    assert_response :success
    assert_select "span.material-symbols-outlined", text: "lock"
  end

  # 自分が作成したイベント一覧
  test "should index" do
    get events_path
    assert_response :success
  end

  test "should paginate created events with infinite scroll frames" do
    user = users(:developer)
    sign_in user
    create_events_for(user, Event::PER_PAGE + 1)

    get events_path(filter: "created")
    assert_response :success
    assert_select "turbo-frame#events_page_1.contents"
    assert_select "turbo-frame#events_page_2[loading=?]", "lazy"
    assert_select "turbo-frame#events_page_2.contents", count: 0
    assert_select "turbo-frame#events_page_2[src*='filter=created']"
    assert_select "turbo-frame#events_page_2[src*='page=2']"
    assert_select "turbo-frame#events_page_1 a[href*='/t/']", count: Event::PER_PAGE
    assert_select "turbo-frame#events_page_1 a[data-turbo-frame=?]", "_top"

    get events_path(filter: "created", page: 2)
    assert_response :success
    assert_select "turbo-frame#events_page_2"
    assert_select "turbo-frame#events_page_2 a[href*='/t/']", minimum: 1
    assert_select "turbo-frame#events_page_3", count: 0
  end

  test "should paginate public events with infinite scroll frames" do
    create_events_for(
      @user,
      Event::PER_PAGE + 1,
      day_date: Date.current + 10.days,
      with_ready_performance: true
    )

    get events_path
    assert_response :success
    assert_select "turbo-frame#events_page_1.contents"
    assert_select "turbo-frame#events_page_2[loading=?]", "lazy"
    assert_select "turbo-frame#events_page_2.contents", count: 0
    assert_select "turbo-frame#events_page_2[src*='page=2']"
    assert_select "h2", text: "もうすぐ開催されるイベント"
    assert_select "a[data-turbo-frame=?]", "_top"

    last_page = last_public_events_page
    get events_path(page: last_page)
    assert_response :success
    assert_select "turbo-frame#events_page_#{last_page}"
    assert_select "turbo-frame#events_page_#{last_page + 1}", count: 0
  end

  # 開催日あり・描画可能な出演情報なしの公開イベントは「出演情報なし」に表示する
  test "should show public events without ready performances under that heading" do
    empty_name = "出演なし公開#{SecureRandom.hex(4)}"
    empty_event = @user.events.create!(
      event_key: "empty-ready-index-#{SecureRandom.urlsafe_base64(4)}",
      event_name_tag: EventNameTag.create!(name: empty_name),
      description: "描画可能出演なし公開",
      visibility: :public,
      created_at: Time.current
    )
    empty_event.days.create!(date: Date.current + 1.day)
    assert_equal 0, empty_event.performances.count

    last_page = last_public_events_page
    found = false
    (1..last_page).each do |page|
      get events_path(page: page)
      assert_response :success
      if response.body.include?(empty_name)
        assert_select "h2", text: "出演情報なし"
        found = true
        break
      end
    end
    assert found, "expected event without ready performances under that heading"
  end

  # 開催日未設定の公開イベントも「出演情報なし」セクションに表示する
  test "should show public events without days under without-ready heading" do
    empty_name = "出演ゼロ公開#{SecureRandom.hex(4)}"
    empty_event = @user.events.create!(
      event_key: "empty-public-index-#{SecureRandom.urlsafe_base64(4)}",
      event_name_tag: EventNameTag.create!(name: empty_name),
      description: "出演情報なし公開",
      visibility: :public,
      created_at: Time.current
    )
    assert_equal 0, empty_event.performances.count
    assert_equal 0, empty_event.days.count

    last_page = last_public_events_page
    found = false
    (1..last_page).each do |page|
      get events_path(page: page)
      assert_response :success
      if response.body.include?(empty_name)
        assert_select "h2", text: "出演情報なし"
        assert_select "p", text: /開催日：未定/
        found = true
        break
      end
    end
    assert found, "expected undated public event under without-ready heading"
  end

  test "should paginate favorite events with infinite scroll frames" do
    user = users(:developer)
    sign_in user
    events = create_events_for(users(:two), Event::PER_PAGE + 1, day_date: Date.current + 5.days)
    events.each { |event| user.event_favorites.create!(event: event) }

    get events_path(filter: "favorites")
    assert_response :success
    assert_select "turbo-frame#events_page_1"
    assert_select "turbo-frame#events_page_2[loading=?]", "lazy"
    assert_select "turbo-frame#events_page_2[src*='filter=favorites']"
    assert_select "turbo-frame#events_page_2[src*='page=2']"

    get events_path(filter: "favorites", page: 2)
    assert_response :success
    assert_select "turbo-frame#events_page_2"
    assert_select "turbo-frame#events_page_3", count: 0
  end

  test "should show past heading when public list includes past events" do
    create_events_for(
      @user,
      Event::PER_PAGE,
      day_date: Date.current - 14.days,
      with_ready_performance: true
    )

    page = 1
    found = false
    100.times do
      result = Event.paginate_public_all(page: page)
      if result[:past_index] && result[:past_index] < result[:events].size
        get events_path(page: page)
        assert_response :success
        assert_select "h2", text: "過去のイベント"
        found = true
        break
      end
      break unless result[:next_page]

      page = result[:next_page]
    end
    assert found, "expected a page that shows the past events heading"
  end

  test "should show lock icon for unpublished event in created list" do
    events(:unpublished).update!(created_at: Time.current)

    get events_path(filter: "created")
    assert_response :success
    assert_select "span.material-symbols-outlined", text: "lock"
  end

  test "should show link icon for unlisted event in created list" do
    events(:unlisted).update!(created_at: Time.current)

    get events_path(filter: "created")
    assert_response :success
    assert_select "span.material-symbols-outlined", text: "link"
  end

  # 一覧のタイムテーブル名は単語途中でも省略される（truncate）
  test "should truncate event name mid-word on index" do
    long_name = "SuperLongTimetableNameWithoutAnySpacesToForceMidWordTruncationOnTheIndexCard"
    @event.event_name_tag.update!(name: long_name)
    @event.update!(created_at: Time.current)

    get events_path(filter: "created")
    assert_response :success
    assert_select "p.truncate[title=?]", long_name, text: /#{Regexp.escape(long_name)}/
  end

  # イベント作成ページを表示
  test "should new event" do
    get new_event_url
    assert_response :success
  end

  # タイムテーブル作成には作成した一覧への戻るボタンがある
  test "new includes back link to created events index" do
    get new_event_url
    assert_response :success
    assert_select "a[href=?][aria-label=?]", events_path(filter: "created"), "一覧へ戻る" do
      assert_select "span.material-symbols-outlined", text: "arrow_back"
      assert_select "span", text: "一覧"
    end
  end

  # イベント作成処理（タグ未存在の場合にイベント作成と同時にタグも作成されることを確認）
  test "should create event and create tag when tag not exists" do
    event_name = "タグ未存在の名前"
    # Event と EventNameTag がそれぞれ1件増えることを確認
    assert_difference([ "Event.count", "EventNameTag.count" ], 1) do
      post events_url, params: {
        event: {
          # ネスト属性でタグ名を送信
          event_name_tag_attributes: { name: event_name },
          description: "説明"
        }
      }
    end
    # 作成されたイベント
    created_event = Event.last
    # 作成されたタグ
    tag = EventNameTag.find_by(name: event_name)

    # タグが作成されていること
    assert_not_nil tag
    # イベントに紐付いていること
    assert_equal tag.id, created_event.event_name_tag_id
    # 正しいリダイレクト先
    assert_redirected_to show_timetable_path(created_event.event_key)
  end

  test "should create private event" do
    event_name = "非公開イベント作成テスト"
    assert_difference("Event.count", 1) do
      post events_url, params: {
        event: {
          event_name_tag_attributes: { name: event_name },
          description: "説明",
          visibility: "private"
        }
      }
    end

    created_event = Event.last
    assert created_event.visibility_private?
  end

  test "should create unlisted event" do
    event_name = "限定公開イベント作成テスト"
    assert_difference("Event.count", 1) do
      post events_url, params: {
        event: {
          event_name_tag_attributes: { name: event_name },
          description: "説明",
          visibility: "unlisted"
        }
      }
    end

    created_event = Event.last
    assert created_event.visibility_unlisted?
  end

  # 1ユーザー内のイベント名が重複する場合は作成できない
  test "should not create overlapping event" do
    overlapping_event_name = "Event1"
    assert_no_difference([ "Event.count" ]) do
      post events_url, params: {
        event: {
          # ネスト属性でタグ名を送信
          event_name_tag_attributes: { name: overlapping_event_name },
          description: "説明"
        }
      }
    end
    assert_response :unprocessable_entity
  end

  # 別のユーザーが作成した同名イベントは作成可能
  test "should create overlapping event in other user" do
    overlapping_event_name = @other_event.display_name
    assert_difference("Event.count") do
      post events_url, params: {
        event: {
          # ネスト属性でタグ名を送信
          event_name_tag_attributes: { name: overlapping_event_name },
          description: "説明"
        }
      }
    end
  end

  # タグ名が100文字以上なら作成できない
  test "should not create when tag name is over 100 characters" do
    long_name = "a" * 101
    post events_url, params: {
      event: {
        event_name_tag_attributes: { name: long_name }
      }
    }
    assert_response :unprocessable_entity
  end

  # 編集フォームを表示
  test "should get edit" do
    get edit_event_url(@event.event_key)
    assert_response :success
  end

  test "should select private visibility when event is private" do
    unpublished_event = events(:unpublished)
    get edit_event_url(unpublished_event.event_key)
    assert_response :success
    assert_select "input[name='event[visibility]'][type=radio][value=private][checked]"
  end

  test "should select public visibility when event is public" do
    get edit_event_url(@event.event_key)
    assert_response :success
    assert_select "input[name='event[visibility]'][type=radio][value=public][checked]"
  end

  # 他者が作成した編集フォームは表示できない
  test "should not get edit form of other user's event" do
    get edit_event_url(@other_event.event_key)
    assert_response :not_found
  end

  # イベント編集処理
  test "should update event and replace tag" do
    new_tag_name = "新しいタグ"

    patch event_url(@event.event_key), params: {
      event: {
        description: "説明更新",
        event_name_tag_attributes: { name: new_tag_name }
      }
    }

    assert_redirected_to event_path(@event.event_key)

    @event.reload

    # イベントのタグが新しいものに置き換わっていること
    assert_equal new_tag_name, @event.event_name_tag.name

    # Event 本体の値も更新されていること
    assert_equal "説明更新", @event.description
  end

  test "should update event visibility" do
    patch event_url(@event.event_key), params: {
      event: {
        description: @event.description,
        visibility: "private",
        event_name_tag_attributes: { name: @event.event_name_tag.name }
      }
    }

    assert_redirected_to event_path(@event.event_key)
    @event.reload
    assert @event.visibility_private?
  end

  # イベント名が空文字の場合は編集できない
  test "should not update when tag name is blank" do
    patch event_url(@event.event_key), params: {
      event: {
        description: "説明変更",
        event_name_tag_attributes: { name: "" }
      }
    }

    assert_response :unprocessable_entity
  end

  # 他者が作成したイベントは編集できない
  test "should not update other user's event" do
    patch event_url(@other_event.event_key), params: {
      event: {
        description: "説明変更",
        event_name_tag_attributes: { name: "" }
      }
    }
    assert_response :not_found
  end

  # タグ名が100文字以上なら編集できない
  test "should not update when tag name is over 100 characters" do
    long_name = "a" * 101
    patch event_url(@event.event_key), params: {
      event: {
        event_name_tag_attributes: { name: long_name }
      }
    }
    assert_response :unprocessable_entity
  end

  # イベント削除処理
  test "should delete event" do
    assert_difference("Event.count", -1) do
      delete event_url(@event.event_key)
    end
    assert_redirected_to events_path(filter: "created")
  end

  # 他人のイベント削除は失敗し、Event.count は変化しない
  test "should not delete event of another user" do
    assert_no_difference "Event.count" do
      delete event_url(@other_event.event_key)
    end
    assert_response :not_found
  end

  private

  # みんなが作った一覧の最終ページ番号を返す
  def last_public_events_page
    page = 1
    100.times do
      result = Event.paginate_public_all(page: page)
      return page unless result[:next_page]

      page = result[:next_page]
    end
    flunk "public events pagination did not reach the last page"
  end

  # ページング検証用にイベントを一括作成する
  def create_events_for(user, count, day_date: nil, with_ready_performance: false)
    Array.new(count) do |i|
      tag = EventNameTag.create!(name: "paging-#{user.id}-#{i}-#{SecureRandom.hex(4)}")
      event = user.events.create!(
        event_key: "paging-#{user.id}-#{i}-#{SecureRandom.urlsafe_base64(4)}",
        event_name_tag: tag,
        description: "ページングテスト",
        visibility: :public
      )
      if day_date
        day = event.days.create!(date: day_date)
        if with_ready_performance
          stage = event.stages.create!(
            stage_name_tag: StageNameTag.create!(name: "paging-stage-#{SecureRandom.hex(4)}")
          )
          performer = event.performers.create!(
            performer_name_tag: PerformerNameTag.create!(name: "paging-performer-#{SecureRandom.hex(4)}")
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
      event
    end
  end
end
