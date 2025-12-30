class StagesController < ApplicationController
  # イベントをセット
  before_action :set_event
  # indexとshow以外のアクションは所有者本人のみアクセス可能
  before_action :authorize_event!, except: %i[index show]
  before_action :set_stage, only: %i[ show edit update destroy ]
  before_action :set_page_title, except: %i[ destroy ]

  # ステージ一覧
  def index
    @stages = @event.stages
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
    stage_name_tag = StageNameTag.find_or_create_by!(name: tag_name)

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

  # ステージ編集処理
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
      return render :edit, status: :unprocessable_entity
    end

    # 既存のタグは更新せず、新しいタグに置き換える
    @stage.stage_name_tag = StageNameTag.find_or_create_by!(name: tag_name)

    # Stage本体を更新（ネストされたフィールドを除く）
    if @stage.update(stage_params.except(:stage_name_tag_attributes))
      redirect_to event_stage_path(@event.event_key, @stage), notice: "ステージを更新しました。"
    else
      render :edit, status: :unprocessable_entity
    end
  end

  # ステージ削除処理
  def destroy
    @stage.destroy!
    redirect_to event_stages_path(@event.event_key), notice: "ステージを削除しました。", status: :see_other
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
          "#{@stage.stage_name_tag.name}"
        when "edit", "update"
          "ステージを編集"
        end
    end

    # 許可するパラメーター
    def stage_params
      params.require(:stage).permit(
        :description,
        :address,
        :position,
        stage_name_tag_attributes: [ :name ] # stage_name_tagに対するエラーの伝播を許可
      )
    end
end
