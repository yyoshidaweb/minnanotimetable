require "test_helper"

class StagesControllerTest < ActionDispatch::IntegrationTest
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

  # ステージ一覧ページ
  test "should get index" do
    get event_stages_url(@event.event_key)
    assert_response :success
  end

  # 未ログインでもステージ一覧ページにアクセス可能
  test "should get index with logout" do
    sign_out @user
    get event_stages_url(@event.event_key)
    assert_response :success
  end

  # ステージ詳細
  test "should get show stage" do
    stage = @event.stages.first
    get event_stage_url(@event.event_key, stage)
    assert_response :success
  end

  # 未ログインでもステージ詳細にアクセス可能
  test "should get show stage with logout" do
    sign_out @user
    stage = @event.stages.first
    get event_stage_url(@event.event_key, stage)
    assert_response :success
  end

  # ステージ追加ページ
  test "should get new" do
    get new_event_stage_url(@event.event_key)
    assert_response :success
  end

  # 他者のステージ追加ページはアクセスできない
  test "should not get new of other user's event" do
    get new_event_stage_url(@other_event.event_key)
    assert_response :not_found
  end

  # ステージ作成処理（タグ未存在の場合にステージ作成と同時にタグも作成されることを確認）
  test "should create stage and create tag when tag not exists" do
    stage_name = "タグ未存在の名前"
    assert_difference([ "Stage.count", "StageNameTag.count" ], 1) do
      post event_stages_path(@event.event_key), params: {
        stage: {
          # ネスト属性でタグ名を送信
          stage_name_tag_attributes: { name: stage_name },
          description: "説明",
          address: "住所"
        }
      }
    end
    # 作成されたステージ
    created_stage = Stage.unscoped.last
    # 作成されたタグ
    tag = StageNameTag.find_by(name: stage_name)

    # タグが作成されていること
    assert_not_nil tag
    # ステージに紐付いていること
    assert_equal tag.id, created_stage.stage_name_tag_id
    # 正しいリダイレクト先
    assert_redirected_to edit_timetable_url(@event.event_key)
  end

  # ステージが空文字の場合は追加できない
  test "should not create blank stage" do
    assert_no_difference("@event.stages.count") do
      post event_stages_path(@event.event_key), params: {
        stage: {
          # ネスト属性でタグ名を送信
          stage_name_tag_attributes: { name: "" },
          description: "説明",
          address: "住所"
        }
      }
    end
    assert_response :unprocessable_entity
  end

  # イベント内のステージが重複する場合は追加できない
  test "should not create overlapping stage" do
    overlapping_stage_name = "Stage1"
    assert_no_difference("@event.stages.count") do
      post event_stages_path(@event.event_key), params: {
        stage: {
          # ネスト属性でタグ名を送信
          stage_name_tag_attributes: { name: overlapping_stage_name },
          description: "説明",
          address: "住所"
        }
      }
    end
    assert_response :unprocessable_entity
  end

  # 別のイベントとステージが重複する場合は追加可能
  test "should create overlapping stage in other event" do
    overlapping_stage_name = "Stage1"
    assert_difference("@event_two.stages.count") do
      post event_stages_path(@event_two.event_key), params: {
        stage: {
          # ネスト属性でタグ名を送信
          stage_name_tag_attributes: { name: overlapping_stage_name },
          description: "説明",
          address: "住所"
        }
      }
    end
    assert_redirected_to edit_timetable_path(@event_two.event_key)
  end

  # ステージ編集ページ
  test "should get edit stage" do
    stage = @event.stages.first
    get edit_event_stage_url(@event.event_key, stage)
    assert_response :success
  end

  # 他者のステージ編集ページはアクセスできない
  test "should not get edit of other user's event" do
    stage = @event.stages.first
    get edit_event_stage_url(@other_event.event_key, stage)
    assert_response :not_found
  end

  # ステージ編集処理
  test "should update stage and replace tag" do
    stage = @event.stages.first
    new_tag_name = "新しいタグ"

    patch event_stage_url(@event.event_key, stage), params: {
      stage: {
        description: "説明更新",
        address: "住所更新",
        stage_name_tag_attributes: { name: new_tag_name }
      }
    }
    assert_redirected_to event_stage_path(@event.event_key, stage)
    stage.reload
    # ステージのタグが新しいものに置き換わっていること
    assert_equal new_tag_name, stage.stage_name_tag.name
    # Stage 本体の値も更新されていること
    assert_equal "説明更新", stage.description
    assert_equal "住所更新", stage.address
  end

  # ステージ名が空文字の場合は編集できない
  test "should not update stage when tag name is blank" do
    stage = @event.stages.first
    patch event_stage_url(@event.event_key, stage), params: {
      stage: {
        description: "説明変更",
        address: "住所変更",
        stage_name_tag_attributes: { name: "" }
      }
    }

    assert_response :unprocessable_entity
  end

  # 他者が作成したステージは編集できない
  test "should not update other user's stage" do
    stage = @other_event.stages.first
    patch event_stage_url(@other_event.event_key, stage), params: {
      stage: {
        description: "説明変更",
        address: "住所変更",
        stage_name_tag_attributes: { name: "" }
      }
    }

    assert_response :not_found
  end

  # ステージ削除
  test "should destroy stage" do
    assert_difference("@event.stages.count", -1) do
      delete event_stage_path(@event.event_key, @event.stages.first)
    end
    assert_redirected_to edit_timetable_path(@event.event_key)
  end

  # 他者のステージは削除できない
  test "should not destroy other user's stage" do
    assert_no_difference("@other_event.stages.count", -1) do
      delete event_stage_path(@other_event.event_key, @other_event.stages.first)
    end
    assert_response :not_found
  end
end
