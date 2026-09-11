require "test_helper"

class TimetablesControllerTest < ActionDispatch::IntegrationTest
  # Devise のテストヘルパーをインクルード
  include Devise::Test::IntegrationHelpers

  setup do
    # Google 認証のテスト用ユーザーを作成
    @user = users(:one)
    @user_two = users(:two)
    @no_ai_usage_user = users(:no_ai_usage)
    # テスト用のログイン状態を再現
    sign_in @user
    @event = events(:one)
    @no_ai_usage_event = events(:no_ai_usage_event)
    @no_performance_event = events(:no_performance_event)
    @day1 = days(:one)
    @day2 = days(:two)
    @no_ai_usage_event_day = days(:no_ai_usage_event_day)
    @no_performance_event_day = days(:no_performance_event_day)
    @performance1 = performances(:one)
    @performance2 = performances(:two)
    @performance3 = performances(:three)
    @performance4 = performances(:four)
    @json = JSON.parse(file_fixture("timetable_json.json").read)
    # ダミーファイル（テストでは解析されないが、画像選択は必須のため使用）
    @dummy_file = fixture_file_upload("public/icon.png")
  end

  # 未ログインでもタイムテーブルページにアクセス可能
  test "should get timetable with logout" do
    sign_out @user
    get show_timetable_path(@event.event_key)
    assert_response :success
  end

  test "should not get unpublished timetable with logout" do
    sign_out @user
    get show_timetable_path(events(:unpublished).event_key)
    assert_response :not_found
    assert_includes response.body, "ページが見つかりません"
  end

  test "should get unlisted timetable with logout" do
    sign_out @user
    get show_timetable_path(events(:unlisted).event_key)
    assert_response :success
  end

  test "should not get unpublished timetable by other user" do
    sign_out @user
    sign_in @user_two
    get show_timetable_path(events(:unpublished).event_key)
    assert_response :not_found
    assert_includes response.body, "ページが見つかりません"
  end

  # デフォルト（最古日付）での表示テスト
  test "should show event timetable by event_key" do
    get show_timetable_path(@event.event_key)
    assert_response :success
    # 全日付へのリンクが含まれている
    assert_select "a[href=?]", show_timetable_path(@event.event_key, d: @day1.date)
    assert_select "a[href=?]", show_timetable_path(@event.event_key, d: @day2.date)
  end

  # 出演情報カードとステージ名は詳細ページへ遷移せずモーダルで開く
  test "performance cards and stage names open detail in modal" do
    get show_timetable_path(@event.event_key)
    assert_response :success
    assert_select "a.stage-header-col[href=?][data-turbo-frame=modal]",
                  event_stage_path(@event.event_key, @performance1.stage)
    assert_select "a[href=?][data-turbo-frame=modal]",
                  event_performer_path(@event.event_key, @performance1.performer)
    assert_select "#favorite_marker_performance_#{@performance1.id}"
  end

  # 入場規制中のステージはバッジを表示し、規制なしでは出さない
  test "shows admission restricted badge under stage name" do
    restricted_stage = @performance1.stage
    restricted_stage.update!(admission_restricted: true)

    get show_timetable_path(@event.event_key)
    assert_response :success
    assert_select "span", text: "入場規制中", count: 1
  end

  # 入場規制オフのときはバッジを出さない（余白行は確保）
  test "hides admission restricted badge when not restricted" do
    get show_timetable_path(@event.event_key)
    assert_response :success
    assert_select "span", text: "入場規制中", count: 0
    assert_select ".stage-admission-status-col", count: @event.stages.count
  end

  # オーナーには下部アクションボタンが常時表示される
  test "owner sees bottom action buttons on timetable" do
    get show_timetable_path(@event.event_key)
    assert_response :success
    assert_select "a[href=?][aria-label=?]", new_event_timetable_path(@event.event_key), "画像から作成"
    assert_select "a[href=?][aria-label=?]", new_event_performance_path(@event.event_key), "出演情報を追加"
  end

  # タイムテーブル画面はページ全体ではなく内側コンテナのみスクロールする
  test "timetable page locks body scroll and scrolls inner container only" do
    get show_timetable_path(@event.event_key)
    assert_response :success
    assert_select "body.h-svh.overflow-hidden"
    assert_select "main.min-h-0.overflow-hidden"
    assert_select "div.flex-1.min-h-0.overflow-auto.overscroll-none"
  end

  # 時刻軸に下余白分の正時（末尾の次の1つ）が表示される
  test "time axis includes bottom spacer hour" do
    get show_timetable_path(@event.event_key)
    assert_response :success
    # day one の最終終了は16:30のため、余白開始の正時は17
    assert_select "p", text: "17"
  end

  # 下余白のCSS変数はRuby定数から:rootへ定義される
  test "bottom spacer css variable is defined from helper constant" do
    get show_timetable_path(@event.event_key)
    assert_response :success
    assert_select "style", text: /--timetable-bottom-spacer:\s*#{TimetablesHelper::TIMETABLE_BOTTOM_SPACER_REM}rem/
  end

  # 他ユーザーには下余白が表示されない
  test "other user does not see bottom spacer on timetable" do
    sign_out @user
    sign_in @user_two
    get show_timetable_path(@event.event_key)
    assert_response :success
    assert_select "p", text: "17", count: 0
    assert_select ".timetable-bottom-spacer-cover", count: 0
    assert_select "style", text: /--timetable-bottom-spacer/, count: 0
  end

  # 未ログインユーザーには下余白が表示されない
  test "guest does not see bottom spacer on timetable" do
    sign_out @user
    get show_timetable_path(@event.event_key)
    assert_response :success
    assert_select "p", text: "17", count: 0
    assert_select ".timetable-bottom-spacer-cover", count: 0
    assert_select "style", text: /--timetable-bottom-spacer/, count: 0
  end

  # 他ユーザーには下部アクションボタンが表示されない
  test "other user does not see bottom action buttons on timetable" do
    sign_out @user
    sign_in @user_two
    get show_timetable_path(@event.event_key)
    assert_response :success
    assert_select "a[href=?]", new_event_timetable_path(@event.event_key), count: 0
    assert_select "a[href=?]", new_event_performance_path(@event.event_key), count: 0
  end

  # 未ログインユーザーには下部アクションボタンが表示されない
  test "guest does not see bottom action buttons on timetable" do
    sign_out @user
    get show_timetable_path(@event.event_key)
    assert_response :success
    assert_select "a[href=?]", new_event_timetable_path(@event.event_key), count: 0
    assert_select "a[href=?]", new_event_performance_path(@event.event_key), count: 0
  end

  # 存在しないイベントキーによるタイムテーブル表示失敗のテスト
  test "should 404 if event_key not found" do
    get "/nonexistent-event-key"
    assert_response :not_found
  end

  # 特定日付指定での表示テスト
  test "should show event with specified date" do
    get show_timetable_path(@event.event_key, d: @day2.date)
    assert_response :success
    # 指定日付の全てのパフォーマンスが含まれている
    assert_select "p", text: @performance3.performer.performer_name_tag.name
    assert_select "p", text: @performance4.performer.performer_name_tag.name
    # 他の日付のパフォーマンスが含まれていなければ成功
    assert_select "p", text: @performance1.performer.performer_name_tag.name, count: 0
    assert_select "p", text: @performance2.performer.performer_name_tag.name, count: 0
  end

  # canonicalはクエリパラメータを含まない正規URLを指す
  test "canonical url excludes date query parameter" do
    get show_timetable_path(@event.event_key, d: @day2.date)
    assert_response :success
    canonical = "http://www.example.com/t/#{@event.event_key}"
    assert_select "link[rel=canonical][href=?]", canonical
    assert_select "meta[property='og:url'][content=?]", canonical
  end

  # 本体の公開タイムテーブルはインデックス対象（noindexしない）
  test "published timetable does not include noindex robots meta" do
    get show_timetable_path(@event.event_key)
    assert_response :success
    assert_select "meta[name=robots][content='noindex, nofollow']", count: 0
  end

  # 出演情報が0件の場合もタイムテーブルを表示できる
  test "should show event timetable by event_key when no performances" do
    get show_timetable_path(@no_performance_event.event_key)
    assert_response :success
  end

  # AIタイムテーブル作成ページにアクセスできる
  test "should get new timetable page" do
    get new_event_timetable_path(@event.event_key)
    assert_response :success
  end

  # 他人のAIタイムテーブル作成ページにはアクセスできない
  test "should not get new timetable page for other users" do
    get new_event_timetable_path(@no_performance_event.event_key)
    assert_response :not_found
  end

  # AIタイムテーブル作成が成功する
  test "should create timetable with AI" do
    sign_out @user
    sign_in @user_two
    # TimetableExtractorをモック（APIは利用せず、常に固定JSONを返す）
    TimetableExtractor.stub :extract, { success: true, data: @json } do
      assert_difference "Stage.count", +2 do
        assert_difference "Performer.count", +3 do
          assert_difference "Performance.count", +3 do
            post event_timetables_path(@no_performance_event.event_key), params: {
              day_id: @no_performance_event_day.id,
              image: @dummy_file
            }
          end
        end
      end
      assert_redirected_to show_timetable_path(@no_performance_event.event_key, d: @no_performance_event_day.date)
    end
  end

  # 他人のAIタイムテーブル作成はできない
  test "should not create timetable with AI for other users" do
    # TimetableExtractorをモック（APIは利用せず、常に固定JSONを返す）
    TimetableExtractor.stub :extract, { success: true, data: @json } do
      post event_timetables_path(@no_performance_event.event_key), params: {
        day_id: @no_performance_event_day.id,
        image: @dummy_file
      }
      assert_response :not_found
    end
  end

  # AIタイムテーブル作成時にJSONパースエラーが発生した場合は作成できない
  test "should not create timetable with AI if JSON parse error occurs" do
    sign_out @user
    sign_in @user_two
    # TimetableExtractorをモック（APIは利用せず、常に失敗した結果だけを返す）
    TimetableExtractor.stub :extract, { success: false, error: "画像解析結果の読み込みに失敗しました" } do
      assert_no_difference "Stage.count" do
        assert_no_difference "Performer.count" do
          assert_no_difference "Performance.count" do
            post event_timetables_path(@no_performance_event.event_key), params: {
              day_id: @no_performance_event_day.id,
              image: @dummy_file
            }
          end
        end
      end
      assert_response :unprocessable_entity
      assert_match "画像解析結果の読み込みに失敗しました", response.body
    end
  end

  # AIタイムテーブル作成時に画像解析が失敗した場合は作成できない
  test "should not create timetable with AI if image parsing fails" do
    sign_out @user
    sign_in @user_two
    # TimetableExtractorをモック（APIは利用せず、常に失敗した結果だけを返す）
    TimetableExtractor.stub :extract, { success: false, error: "画像解析に失敗しました" } do
      post event_timetables_path(@no_performance_event.event_key), params: {
        day_id: @no_performance_event_day.id,
        image: @dummy_file
      }
      assert_response :unprocessable_entity
      assert_match "画像解析に失敗しました", response.body
    end
  end

  # AIタイムテーブル作成時に画像が選択されていない場合は作成できない
  test "should not create timetable with AI if no image is selected" do
    sign_out @user
    sign_in @user_two
    assert_no_difference "Stage.count" do
      assert_no_difference "Performer.count" do
        assert_no_difference "Performance.count" do
          post event_timetables_path(@no_performance_event.event_key), params: {
            day_id: @no_performance_event_day.id
          }
        end
      end
    end
    assert_response :unprocessable_entity
    assert_match "画像を選択してください", response.body
  end

  # AIタイムテーブル作成時に開催日が選択されていない場合は作成できない
  test "should not create timetable with AI if no day is selected" do
    sign_out @user
    sign_in @user_two
    assert_no_difference "Stage.count" do
      assert_no_difference "Performer.count" do
        assert_no_difference "Performance.count" do
          post event_timetables_path(@no_performance_event.event_key), params: {
            image: @dummy_file
          }
        end
      end
    end
    assert_response :unprocessable_entity
    assert_match "開催日を選択してください", response.body
  end

  # AIタイムテーブル作成時にJPEG, PNG以外のファイルが選択された場合は作成できない
  test "should not create timetable with AI if non-image file is selected" do
    sign_out @user
    sign_in @user_two
    non_image_file = fixture_file_upload("sample.txt")
    assert_no_difference "Stage.count" do
      assert_no_difference "Performer.count" do
        assert_no_difference "Performance.count" do
          post event_timetables_path(@no_performance_event.event_key), params: {
            day_id: @no_performance_event_day.id,
            image: non_image_file
          }
        end
      end
    end
    assert_response :unprocessable_entity
    assert_match "JPEG, PNG形式のみアップロード可能です", response.body
  end

  # Aiタイムテーブル作成時に既存の出演情報が存在する場合はそれらが削除される
  test "should delete existing performances when creating timetable with AI" do
    # 既存のperformanceが存在することを確認
    assert Performance.where(day: @event).exists?
    # 選択された開催日の既存のperformanceの数を確認
    performance_count = Performance.where(day: @day1).count
    TimetableExtractor.stub :extract, { success: true, data: @json } do
      # AIタイムテーブル作成後に既存のperformanceが削除され、新しいperformanceが作成されることを確認
      assert_difference "Performance.count", -performance_count + 3 do
        post event_timetables_path(@event.event_key), params: {
          day_id: @day1.id,
          image: @dummy_file
        }
      end
    end
  end

  # AIタイムテーブル作成失敗時に既存の出演情報が削除されない
  test "should not delete existing performances if creating timetable with AI fails" do
    # 既存のperformanceが存在することを確認
    assert Performance.where(day: @event).exists?
    TimetableExtractor.stub :extract, { success: false, error: "画像解析に失敗しました" } do
      # AIタイムテーブル作成が失敗しても既存のperformanceが削除されないことを確認
      assert_no_difference "Performance.count" do
        post event_timetables_path(@event.event_key), params: {
          day_id: @day1.id,
          image: @dummy_file
        }
      end
    end
  end

  # AI利用上限に達している場合はAIタイムテーブルが作成できない
  test "should not create timetable with AI if AI usage limit is reached" do
    sign_out @user
    sign_in @no_ai_usage_user
    assert_no_difference "Stage.count" do
      assert_no_difference "Performer.count" do
        assert_no_difference "Performance.count" do
          post event_timetables_path(@no_ai_usage_event.event_key), params: {
            day_id: @no_ai_usage_event_day.id,
            image: @dummy_file
          }
        end
      end
    end
    assert_response :unprocessable_entity
    assert_match "今月の使用回数の上限に達しました", response.body
  end
end
