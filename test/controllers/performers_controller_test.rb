require "test_helper"

class PerformersControllerTest < ActionDispatch::IntegrationTest
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
    @event_two = events(:two)
    @other_event = events(:four)
    @current_day = Date.current
  end

  # 出演者一覧ページ
  test "should get index" do
    get event_performers_url(@event.event_key)
    assert_response :success
  end

  # 未ログインでも出演者一覧ページにアクセス可能
  test "should get index with logout" do
    sign_out @user
    get event_performers_url(@event.event_key)
    assert_response :success
  end

  test "should not get unpublished event performers with logout" do
    sign_out @user
    get event_performers_url(events(:unpublished).event_key)
    assert_response :not_found
  end

  test "should not get unpublished event performers by other user" do
    sign_out @user
    sign_in users(:two)
    get event_performers_url(events(:unpublished).event_key)
    assert_response :not_found
  end

  # 出演者詳細
  test "should get show" do
    performer = @event.performers.first
    get event_performer_url(@event.event_key, performer)
    assert_response :success
  end

  # 出演者詳細には一覧への戻るボタンがある
  test "show includes back link to performers index" do
    performer = @event.performers.first
    get event_performer_url(@event.event_key, performer)
    assert_response :success
    assert_select "a[href=?][aria-label=?]", event_performers_path(@event.event_key), "一覧へ戻る" do
      assert_select "span.material-symbols-outlined", text: "arrow_back"
      assert_select "span", text: "一覧"
    end
  end

  # 出演者一覧タブには戻るボタンを付けない
  test "index does not include back link" do
    get event_performers_url(@event.event_key)
    assert_response :success
    assert_select "a[aria-label$=戻る]", count: 0
  end

  # 未ログインでも出演者詳細にアクセス可能
  test "should get show with logout" do
    sign_out @user
    performer = @event.performers.first
    get event_performer_url(@event.event_key, performer)
    assert_response :success
  end

  # 通常の詳細はページ表示で、モーダル用オーバーレイは出さない
  test "show renders full page without modal overlay" do
    performer = @event.performers.first
    get event_performer_url(@event.event_key, performer)
    assert_response :success
    assert_select "h1", text: performer.display_name
    assert_select "div[data-controller='modal'][data-action='click->modal#close']", count: 0
  end

  # Turbo Frameでは出演者詳細をモーダルとして返す
  test "show renders modal when requested as turbo frame" do
    performer = @event.performers.first
    get event_performer_url(@event.event_key, performer),
        headers: { "Turbo-Frame" => "modal" }
    assert_response :success
    assert_select "turbo-frame#modal" do
      assert_select "div[data-controller='modal'][data-action='click->modal#close']"
      assert_select "button[data-action='click->modal#close']"
      assert_select "h1", text: performer.display_name
      assert_select "a[href=?][data-action=?]",
                    edit_event_performer_path(@event.event_key, performer),
                    "click->modal#navigate"
      performance = performer.performances.first
      assert_not_nil performance
      assert_select "a[href=?][data-action=?]",
                    edit_event_performance_path(@event.event_key, performance),
                    "click->modal#navigate"
      assert_select "a[href=?][data-turbo-frame=_top]",
                    event_performer_path(@event.event_key, performer),
                    text: "詳細→"
    end
  end

  # 未ログインのモーダルには詳細リンクと編集ボタンを出さない
  test "show modal hides detail link and edit for guest" do
    sign_out @user
    performer = @event.performers.first
    get event_performer_url(@event.event_key, performer),
        headers: { "Turbo-Frame" => "modal" }
    assert_response :success
    assert_select "a", text: "詳細→", count: 0
    assert_select "a[href=?]", edit_event_performer_path(@event.event_key, performer), count: 0
  end

  # 他ユーザーのモーダルにも詳細リンクと編集ボタンを出さない
  test "show modal hides detail link and edit for other user" do
    sign_out @user
    sign_in users(:two)
    performer = @event.performers.first
    get event_performer_url(@event.event_key, performer),
        headers: { "Turbo-Frame" => "modal" }
    assert_response :success
    assert_select "a", text: "詳細→", count: 0
    assert_select "a[href=?]", edit_event_performer_path(@event.event_key, performer), count: 0
  end

  # 出演者カードの先頭出演は6時起点の順（22:00が01:00より先）
  test "index card shows earliest festival performance first" do
    performer = create_overnight_performer

    get event_performers_url(@event.event_key)
    assert_response :success
    assert_select "a[href=?]", event_performer_path(@event.event_key, performer) do
      assert_select "p", text: /22:00~/
      assert_select "p", text: /25:00~/, count: 0
    end
  end

  # 所有者には未設定項目バッジとフィルタリンクを表示する
  test "index shows unset field badges and filter for owner" do
    incomplete_performer = create_incomplete_performer
    empty_performer = create_performer_without_performances

    get event_performers_url(@event.event_key)
    assert_response :success
    assert_select "a[href=?]", event_performers_path(@event.event_key, filter: "unset"),
                  text: "未設定項目あり"

    assert_select "a[href=?]", event_performer_path(@event.event_key, incomplete_performer) do
      assert_select "span.performer-unset-field-badge", text: "出演日が未設定です"
      assert_select "span.performer-unset-field-badge", text: "時刻が未設定です"
      assert_select "span.performer-unset-field-badge", text: "ステージが未設定です"
    end
    assert_select "a[href=?]", event_performer_path(@event.event_key, empty_performer) do
      assert_select "span.performer-unset-field-badge", text: "出演情報が未設定です"
    end
    assert_select "a[href=?]", event_performer_path(@event.event_key, performers(:one)) do
      assert_select "span.performer-unset-field-badge", count: 0
    end
  end

  # 未ログインでは未設定バッジとフィルタを出さない
  test "index hides unset field badges and filter for guest" do
    create_incomplete_performer
    sign_out @user

    get event_performers_url(@event.event_key)
    assert_response :success
    assert_select "a", text: "未設定項目あり", count: 0
    assert_select "span.performer-unset-field-badge", count: 0
  end

  # 他ユーザーでも未設定バッジとフィルタを出さない
  test "index hides unset field badges and filter for other user" do
    create_incomplete_performer
    sign_out @user
    sign_in users(:two)

    get event_performers_url(@event.event_key)
    assert_response :success
    assert_select "a", text: "未設定項目あり", count: 0
    assert_select "span.performer-unset-field-badge", count: 0
  end

  # 所有者の「未設定項目あり」フィルタは未設定の出演者のみ表示する
  test "index filter unset shows only performers with unset items for owner" do
    incomplete_performer = create_incomplete_performer
    empty_performer = create_performer_without_performances
    complete_performer = performers(:one)

    get event_performers_url(@event.event_key, filter: "unset")
    assert_response :success
    assert_select "a[href=?]", event_performers_path(@event.event_key), text: "すべて表示"
    assert_select "a[href=?]", event_performer_path(@event.event_key, incomplete_performer)
    assert_select "a[href=?]", event_performer_path(@event.event_key, empty_performer)
    assert_select "a[href=?]", event_performer_path(@event.event_key, complete_performer), count: 0
  end

  # 非所有者は filter=unset を指定しても絞り込みされない
  test "index ignores unset filter for non-owner" do
    create_incomplete_performer
    sign_out @user

    get event_performers_url(@event.event_key, filter: "unset")
    assert_response :success
    assert_select "a[href=?]", event_performer_path(@event.event_key, performers(:one))
    assert_select "a", text: "すべて表示", count: 0
  end

  # 出演者詳細の出演一覧も6時起点の順
  test "show lists performances in festival time order" do
    performer = create_overnight_performer

    get event_performer_url(@event.event_key, performer)
    assert_response :success
    body = response.body
    assert_operator body.index("22:00~"), :<, body.index("25:00~")
  end

  # 出演者追加ページ
  test "should get new" do
    get new_event_performer_url(@event.event_key)
    assert_response :success
  end

  # 他者の出演者追加ページはアクセスできない
  test "should not get new of other user's event" do
    get new_event_performer_url(@other_event.event_key)
    assert_response :not_found
  end

  # 通常遷移で出演者作成処理（タグ未存在の場合に出演者作成と同時にタグも作成されることを確認）
  test "should create performer and create tag when tag not exists" do
    performer_name = "タグ未存在の名前"
    assert_difference([ "Performer.count", "PerformerNameTag.count" ], 1) do
      post event_performers_path(@event.event_key), params: {
        performer: {
          # ネスト属性でタグ名を送信
          performer_name_tag_attributes: { name: performer_name },
          description: "説明",
          website_url: "https://example.com"
        }
      }
    end
    # 作成された出演者
    created_performer = Performer.last
    # 作成されたタグ
    tag = PerformerNameTag.find_by(name: performer_name)

    # タグが作成されていること
    assert_not_nil tag
    # 出演者に紐付いていること
    assert_equal tag.id, created_performer.performer_name_tag_id
    # 正しいリダイレクト先
    assert_redirected_to event_performers_path(@event.event_key)
  end

  # モーダル表示で作成後にモーダルが閉じる
  test "turbo_stream: performer is created and modal is closed" do
    performer_name = "タグ未存在の名前"
    assert_difference([ "Performer.count", "PerformerNameTag.count" ], 1) do
      post event_performers_path(@event.event_key), params: {
        performer: {
          # ネスト属性でタグ名を送信
          performer_name_tag_attributes: { name: performer_name },
          description: "説明",
          website_url: "https://example.com"
        }
      },
      headers: { "Accept" => "text/vnd.turbo-stream.html" } # Turbo Streamとして送信
    end

    assert_response :success
    assert_equal "text/vnd.turbo-stream.html", response.media_type

    # モーダルを閉じる Turbo Stream が返っているか
    assert_includes response.body, 'turbo-stream action="update" target="modal"'
  end

  # 出演者が空文字の場合は追加できない
  test "should not create blank performer" do
    assert_no_difference("@event.performers.count") do
      post event_performers_path(@event.event_key), params: {
        performer: {
          # ネスト属性でタグ名を送信
          performer_name_tag_attributes: { name: "" },
          description: "説明",
          website_url: "https://example.com"
        }
      }
    end
    assert_response :unprocessable_entity
  end

  # タグ名が100文字以上なら作成できない
  test "should not create when tag name is over 100 characters" do
    long_name = "a" * 101
    post event_performers_path(@event.event_key), params: {
      performer: {
        performer_name_tag_attributes: { name: long_name }
      }
    }
    assert_response :unprocessable_entity
  end

  # website_urlがURL形式ではない場合は追加できない
  test "should not create performer if website_url is not url format" do
    performer_name = "タグ未存在の名前"
    assert_no_difference("@event.performers.count") do
      post event_performers_path(@event.event_key), params: {
        performer: {
          # ネスト属性でタグ名を送信
          performer_name_tag_attributes: { name: performer_name },
          description: "説明",
          website_url: "URL形式ではない文字列"
        }
      }
    end
    assert_response :unprocessable_entity
  end

  # イベント内の出演者が重複する場合は追加できない
  test "should not create overlapping performer" do
    overlapping_performer_name = "Performer1"
    assert_no_difference("@event.performers.count") do
      post event_performers_path(@event.event_key), params: {
        performer: {
          # ネスト属性でタグ名を送信
          performer_name_tag_attributes: { name: overlapping_performer_name },
          description: "説明",
          website_url: "https://example.com"
        }
      }
    end
    assert_response :unprocessable_entity
  end

  # 別のイベントと出演者が重複する場合は追加可能
  test "should create overlapping performer in other event" do
    overlapping_performer_name = "Performer1"
    assert_difference("@event_two.performers.count") do
      post event_performers_path(@event_two.event_key), params: {
        performer: {
          # ネスト属性でタグ名を送信
          performer_name_tag_attributes: { name: overlapping_performer_name },
          description: "説明",
          website_url: "https://example.com"
        }
      }
    end
    assert_redirected_to event_performers_path(@event_two.event_key)
  end

  # 出演者編集ページ
  test "should get edit performer" do
    performer = @event.performers.first
    get edit_event_performer_url(@event.event_key, performer)
    assert_response :success
  end

  # Turbo Frameでは出演者編集をモーダルとして返す（showと同様にlayoutなし）
  test "edit renders modal when requested as turbo frame" do
    performer = @event.performers.first
    get edit_event_performer_url(@event.event_key, performer),
        headers: { "Turbo-Frame" => "modal" }
    assert_response :success
    assert_equal 1, response.body.scan(/<turbo-frame[^>]*id="modal"/).size
    assert_no_match /<main/, response.body
    assert_select "turbo-frame#modal" do
      assert_select "input[type=submit][value=?]", "更新"
      assert_select "a[href=?][data-action=?]",
                    event_performer_path(@event.event_key, performer),
                    "click->modal#navigate",
                    text: "キャンセル"
    end
  end

  # 詳細モーダルから編集モーダルへ差し替え可能
  test "show modal edit link navigates to modal edit form" do
    performer = @event.performers.first
    get event_performer_url(@event.event_key, performer),
        headers: { "Turbo-Frame" => "modal" }
    assert_response :success
    assert_select "a[href=?][data-action=?]",
                  edit_event_performer_path(@event.event_key, performer),
                  "click->modal#navigate"

    get edit_event_performer_url(@event.event_key, performer),
        headers: { "Turbo-Frame" => "modal" }
    assert_response :success
    assert_select "turbo-frame#modal input[type=submit][value=?]", "更新"
  end

  # モーダルから更新すると元のページへリダイレクトする
  test "modal update redirects back to referer" do
    performer = @event.performers.first
    timetable_url = show_timetable_url(@event.event_key)
    patch event_performer_url(@event.event_key, performer),
          params: {
            from_modal: "1",
            performer: {
              description: "モーダルから更新",
              website_url: "https://example.com",
              performer_name_tag_attributes: { name: performer.display_name }
            }
          },
          headers: { "HTTP_REFERER" => timetable_url }
    assert_redirected_to timetable_url
    performer.reload
    assert_equal "モーダルから更新", performer.description
  end

  # モーダルから更新時、外部Refererは無視してタイムテーブルへ戻る
  test "modal update ignores external referer" do
    performer = @event.performers.first
    patch event_performer_url(@event.event_key, performer),
          params: {
            from_modal: "1",
            performer: {
              description: "モーダルから更新",
              performer_name_tag_attributes: { name: performer.display_name }
            }
          },
          headers: { "HTTP_REFERER" => "https://evil.example/phishing" }
    assert_redirected_to show_timetable_url(@event.event_key)
  end

  # モーダルから更新時、不正なRefererは無視してタイムテーブルへ戻る
  test "modal update ignores malformed referer" do
    performer = @event.performers.first
    patch event_performer_url(@event.event_key, performer),
          params: {
            from_modal: "1",
            performer: {
              description: "モーダルから更新",
              performer_name_tag_attributes: { name: performer.display_name }
            }
          },
          headers: { "HTTP_REFERER" => "evil" }
    assert_redirected_to show_timetable_url(@event.event_key)
  end

  # モーダルからの更新失敗時はモーダル内にエラーを表示する
  test "modal update with blank tag name replaces modal with errors" do
    performer = @event.performers.first
    timetable_url = show_timetable_url(@event.event_key)
    patch event_performer_url(@event.event_key, performer),
          params: {
            from_modal: "1",
            performer: {
              performer_name_tag_attributes: { name: "" }
            }
          },
          headers: {
            "HTTP_REFERER" => timetable_url,
            "Accept" => "text/vnd.turbo-stream.html, text/html"
          }
    assert_response :unprocessable_entity
    assert_includes response.media_type, "text/vnd.turbo-stream.html"
    assert_match(/turbo-stream action="replace" target="modal"/, response.body)
    assert_match(/出演者名を入力してください/, response.body)
    assert_select "turbo-stream", count: 1
  end

  # 他者の出演者編集ページはアクセスできない
  test "should not get edit of other user's event" do
    performer = @event.performers.first
    get edit_event_performer_url(@other_event.event_key, performer)
    assert_response :not_found
  end

  # 出演者編集処理
  test "should update performer and replace tag" do
    performer = @event.performers.first
    new_tag_name = "新しいタグ"

    patch event_performer_url(@event.event_key, performer), params: {
      performer: {
        description: "説明更新",
        website_url: "https://example.com",
        performer_name_tag_attributes: { name: new_tag_name }
      }
    }
    assert_redirected_to event_performer_path(@event.event_key, performer)
    performer.reload
    # 出演者のタグが新しいものに置き換わっていること
    assert_equal new_tag_name, performer.performer_name_tag.name
    # Performer 本体の値も更新されていること
    assert_equal "説明更新", performer.description
    assert_equal "https://example.com", performer.website_url
  end

  # 出演者名が空文字の場合は編集できない
  test "should not update performer when tag name is blank" do
    performer = @event.performers.first
    patch event_performer_url(@event.event_key, performer), params: {
      performer: {
        description: "説明変更",
        website_url: "https://example.com",
        performer_name_tag_attributes: { name: "" }
      }
    }

    assert_response :unprocessable_entity
  end

  # 他者が作成した出演者は編集できない
  test "should not update other user's performer" do
    performer = @other_event.performers.first
    patch event_performer_url(@other_event.event_key, performer), params: {
      performer: {
        description: "説明変更",
        website_url: "https://example.com",
        performer_name_tag_attributes: { name: "新しい名前" }
      }
    }

    assert_response :not_found
  end

  # タグ名が100文字以上なら編集できない
  test "should not update when tag name is over 100 characters" do
    performer = @event.performers.first
    long_name = "a" * 101
    patch event_performer_url(@event.event_key, performer), params: {
      performer: {
        performer_name_tag_attributes: { name: long_name }
      }
    }
    assert_response :unprocessable_entity
  end

  # 出演者削除
  test "should destroy performer" do
    assert_difference("@event.performers.count", -1) do
      delete event_performer_path(@event.event_key, @event.performers.first)
    end
    assert_redirected_to event_performers_path(@event.event_key)
  end

  # 他者の出演者は削除できない
  test "should not destroy other user's performer" do
    assert_no_difference("@other_event.performers.count", -1) do
      delete event_performer_path(@other_event.event_key, @other_event.performers.first)
    end
    assert_response :not_found
  end

  private
    def create_overnight_performer
      tag = PerformerNameTag.create!(name: "オールナイト出演者")
      performer = @event.performers.create!(performer_name_tag: tag)
      day = @event.days.first
      Performance.create!(
        performer: performer,
        day: day,
        stage: @event.stages.first,
        start_time: Time.zone.parse("01:00"),
        duration: 30
      )
      Performance.create!(
        performer: performer,
        day: day,
        stage: @event.stages.second,
        start_time: Time.zone.parse("22:00"),
        duration: 30
      )
      performer
    end

    def create_incomplete_performer
      tag = PerformerNameTag.create!(name: "未設定出演者")
      performer = @event.performers.create!(performer_name_tag: tag)
      Performance.create!(performer: performer)
      performer
    end

    def create_performer_without_performances
      tag = PerformerNameTag.create!(name: "出演情報なし出演者")
      @event.performers.create!(performer_name_tag: tag)
    end
end
