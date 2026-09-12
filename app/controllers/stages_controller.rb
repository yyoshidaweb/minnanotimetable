class StagesController < ApplicationController
  # イベントをセット
  before_action :set_event
  # indexとshow以外のアクションは所有者本人のみアクセス可能
  before_action :authorize_event!, except: %i[index show]
  # 非公開イベントの閲覧制御（公開ページ）
  before_action :authorize_published_event_access!, only: %i[ index show ]
  before_action :set_stage, only: %i[ show edit update destroy ]
  before_action :set_page_title, except: %i[ destroy ]
  before_action :show_event_header, except: %i[ destroy ]
  # モーダル表示時はレイアウトの空turbo-frame#modalと重ならないようにする
  layout -> { (modal_turbo_frame? && %w[show edit].include?(action_name)) ? false : "application" }

  # ステージ一覧
  def index
    @stages = @event.stages.order(:position).includes(:stage_name_tag)
  end

  # ステージ
  def show
  end

  # ステージ追加ページ
  def new
    @stage = @event.stages.build
    @stage.build_stage_name_tag
  end

  # ステージ作成処理
  def create
    @stages = @event.stages.order(:position).includes(:stage_name_tag)
    @stage = @event.stages.build(stage_params)

    # フォームで受け取るタグ名（fields_for で post される形）
    tag_name = params.dig(:stage, :stage_name_tag_attributes, :name)&.strip

    # タグ名が空ならエラーにする
    if tag_name.blank?
      # nested object を用意してエラーメッセージをビューで表示させる
      @stage.build_stage_name_tag(name: tag_name)
      # 子モデルにエラーを付ける
      @stage.stage_name_tag.errors.add(:name, :blank)
      # 親にエラーを伝える（Deviseエラー表示コンポーネントで表示するため）
      @stage.errors.add(:base, @stage.stage_name_tag.errors.full_messages.first)
      return render :new, status: :unprocessable_entity
    end
    # 既存のタグがあれば使い、なければ作成（ユニーク制約はunique index により DB レベルで防ぐ）
    stage_name_tag = StageNameTag.find_or_initialize_by(name: tag_name)

    # タグのバリデーションチェック
    unless stage_name_tag.save
      @stage.build_stage_name_tag(name: tag_name)
      @stage.stage_name_tag.errors.copy!(stage_name_tag.errors) # 子モデルのエラーをコピー
      @stage.errors.add(:base, stage_name_tag.errors.full_messages.first)
      return render :new, status: :unprocessable_entity
    end

    # Stage に紐付け
    @stage.stage_name_tag = stage_name_tag

    if @stage.save
      respond_to do |format|
        format.turbo_stream
        format.html { redirect_to event_stages_path(@event.event_key), notice: "ステージを作成しました。" }
      end
    else
      render :new, status: :unprocessable_entity
    end
  end

  # ステージ編集ページ
  def edit
  end

  # ステージ更新。
  # from_modal 送信時は成功後 modal_return_url へ、失敗時は turbo-stream で #modal を差し替える。
  def update
    # フォームのタグ名を取得
    tag_name = params.dig(:stage, :stage_name_tag_attributes, :name)&.strip

    # タグ名が空欄ならエラー
    if tag_name.blank?
      # 既存の nested attributes 用オブジェクトを差し込む
      @stage.build_stage_name_tag(name: tag_name) unless @stage.stage_name_tag
      # 子モデルにエラーを付ける
      @stage.stage_name_tag.errors.add(:name, :blank)
      # 親にエラーを伝える
      @stage.errors.add(:base, @stage.stage_name_tag.errors.full_messages.first)
      return render_edit_unprocessable("stages/modal_edit")
    end

    # 既存タグを探す or 新規作成
    stage_name_tag = StageNameTag.find_or_initialize_by(name: tag_name)

    # タグのバリデーションチェック
    unless stage_name_tag.valid?
      # 入力値をフォームに残す
      @stage.stage_name_tag = stage_name_tag
      @stage.stage_name_tag.errors.copy!(stage_name_tag.errors)
      @stage.errors.add(:base, stage_name_tag.errors.full_messages.first)
      return render_edit_unprocessable("stages/modal_edit")
    end

    stage_name_tag.save if stage_name_tag.new_record?

    # Stage に新しいタグを紐付け
    @stage.stage_name_tag = stage_name_tag

    # Stage本体を更新（ネストされたフィールドを除く）
    if @stage.update(stage_params.except(:stage_name_tag_attributes))
      if modal_form_submission?
        redirect_to modal_return_url, notice: "ステージを更新しました。", status: :see_other
      else
        redirect_to event_stage_path(@event.event_key, @stage), notice: "ステージを更新しました。"
      end
    else
      render_edit_unprocessable("stages/modal_edit")
    end
  end

  # ステージ削除処理。
  # from_modal 送信時は modal_return_url へ、通常時はステージ一覧へ戻る。
  def destroy
    @stage.destroy!
    if modal_form_submission?
      redirect_to modal_return_url, notice: "ステージを削除しました。", status: :see_other
    else
      redirect_to event_stages_path(@event.event_key), notice: "ステージを削除しました。", status: :see_other
    end
  end

  # ステージ並び替えページ
  def sort
    @stages = @event.stages.order(:position).includes(:stage_name_tag)
  end

  # ステージ並び替え処理
  def update_sort
    stage_ids = params[:stage_ids]
    stage_ids.each_with_index do |id, index|
      @event.stages.where(id: id).update_all(position: index)
    end
    redirect_to event_stages_path(@event.event_key),
                notice: "ステージの並び順を保存しました"
  end

  private
    # イベントを取得
    def set_event
      @event = Event.find_by!(event_key: params[:event_event_key])
    end

    # イベントの所有者かどうかチェック（異なる場合は404エラーを発生させる）
    def authorize_event!
      raise ActiveRecord::RecordNotFound unless @event.user == current_user
    end

    # 非公開イベントは作成者のみ閲覧可能
    def authorize_published_event_access!
      authorize_published_event!(@event)
    end

    # ステージを取得
    def set_stage
      @stage = @event.stages.find(params[:id])
    end

    # ページタイトルを設定
    def set_page_title
      @page_title =
        case action_name
        when "index"
          "ステージ一覧"
        when "new", "create"
          "ステージを作成"
        when "show"
          "ステージ詳細"
        when "edit", "update"
          "ステージを編集"
        when "sort", "update_sort"
          "ステージを並び替え"
        end
    end

    # イベントヘッダー表示フラグ
    def show_event_header
      # イベント用ヘッダー表示フラグ
      @show_event_header = true
    end

    # 許可するパラメーター
    def stage_params
      params.require(:stage).permit(
        :description,
        :address,
        :admission_restricted,
        :position,
        stage_name_tag_attributes: [ :name ] # stage_name_tagに対するエラーの伝播を許可
      )
    end
end
