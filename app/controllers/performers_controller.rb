class PerformersController < ApplicationController
  # イベントをセット
  before_action :set_event
  # indexとshow以外のアクションは所有者本人のみアクセス可能
  before_action :authorize_event!, except: %i[index show]
  before_action :set_performer, only: %i[ show edit update destroy ]
  before_action :set_page_title, except: %i[ destroy ]

  def index
    @performers = @event.performers
  end

  def show
  end

  def new
    @performer = @event.performers.build
    @performer.build_performer_name_tag
  end

  def create
    @performer = @event.performers.build(performer_params)

    # フォームで受け取るタグ名（fields_for で post される形）
    tag_name = params.dig(:performer, :performer_name_tag_attributes, :name)&.strip

    # タグ名が空ならエラーにする
    if tag_name.blank?
      # nested object を用意してエラーメッセージをビューで表示させる
      @performer.build_performer_name_tag(name: tag_name)
      # 子モデルにエラーを付ける
      @performer.performer_name_tag.errors.add(:name, :blank)
      # 親にエラーを伝える（Deviseエラー表示コンポーネントで表示するため）
      @performer.errors.add(:base, @performer.performer_name_tag.errors.full_messages.first)
      return render :new, status: :unprocessable_entity
    end
    # 既存のタグがあれば使い、なければ作成（ユニーク制約はunique index により DB レベルで防ぐ）
    performer_name_tag = PerformerNameTag.find_or_create_by!(name: tag_name)

    # Performer に紐付け
    @performer.performer_name_tag = performer_name_tag

    if @performer.save
      redirect_to event_performers_path(@event.event_key), notice: "出演者を作成しました。"
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    # フォームのタグ名を取得
    tag_name = params.dig(:performer, :performer_name_tag_attributes, :name)&.strip

    # タグ名が空欄ならエラー
    if tag_name.blank?
      # 既存の nested attributes 用オブジェクトを差し込む
      @performer.build_performer_name_tag(name: tag_name) unless @performer.performer_name_tag
      # 子モデルにエラーを付ける
      @performer.performer_name_tag.errors.add(:name, :blank)
      # 親にエラーを伝える
      @performer.errors.add(:base, @performer.performer_name_tag.errors.full_messages.first)
      return render :edit, status: :unprocessable_entity
    end

    # 既存のタグは更新せず、新しいタグに置き換える
    @performer.performer_name_tag = PerformerNameTag.find_or_create_by!(name: tag_name)

    # Performer本体を更新（ネストされたフィールドを除く）
    if @performer.update(performer_params.except(:performer_name_tag_attributes))
      redirect_to edit_timetable_path(@event.event_key), notice: "出演者を更新しました。"
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @performer.destroy!
    redirect_to edit_timetable_path(@event.event_key), notice: "出演者を削除しました。", status: :see_other
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

    # 出演者を取得
    def set_performer
      @performer = @event.performers.find(params[:id])
    end

    # ページタイトルを設定
    def set_page_title
      @page_title =
        case action_name
        when "index"
          "出演者一覧"
        when "new", "create"
          "出演者を作成"
        when "show"
          "#{@performer.performer_name_tag.name}"
        when "edit", "update"
          "出演者を編集"
        end
    end

    # 許可するパラメーター
    def performer_params
      params.require(:performer).permit(
        :description,
        :website_url,
        performer_name_tag_attributes: [ :name ] # performer_name_tagに対するエラーの伝播を許可
      )
    end
end
