class EventsController < ApplicationController
  # ログイン必須（show以外）
  before_action :authenticate_user!, only: [ :index, :new, :create, :update ]

  # ログインユーザーが持つイベントのみ取得するフィルタ（見つからない場合は404エラー）
  before_action :set_event, only: [ :edit, :update, :destroy ]

  # 作成したイベント一覧
  def index
    # 自分が作成したイベントのみ取得（最新順）
    @events = current_user.events.order(created_at: :desc)
    @page_title = "作成したイベント一覧"
  end

  # 未ログインでも閲覧可能
  def show
    @event = Event.find_by!(event_key: params[:event_key])
    @page_title = "#{@event.event_name_tag.name} 概要"
  end

  # イベント作成ページ表示
  def new
    @event = Event.new
    # nested form 用に空のタグオブジェクトを用意
    @event.build_event_name_tag
    @page_title = "イベント作成"
  end

  # イベント作成処理
  def create
    # Event 本体のパラメータ（description 等）を受け取る
    @event = current_user.events.build(event_params)

    # フォームで受け取るタグ名（fields_for で post される形）
    tag_name = params.dig(:event, :event_name_tag_attributes, :name)&.strip

    # タグ名が空ならエラーにする
    if tag_name.blank?
      # nested object を用意してエラーメッセージをビューで表示させる
      @event.build_event_name_tag(name: tag_name)
      # 子モデルにエラーを付ける
      @event.event_name_tag.errors.add(:name, :blank)
      # 親にエラーを伝える（Deviseエラー表示コンポーネントで表示するため）
      @event.errors.add(:base, @event.event_name_tag.errors.full_messages.first)
      return render :new, status: :unprocessable_entity
    end

    # 既存のタグがあれば使い、なければ作成（ユニーク制約はunique index により DB レベルで防ぐ）
    event_name_tag = EventNameTag.find_or_create_by!(name: tag_name)

    # Event に紐付け
    @event.event_name_tag = event_name_tag

    # event_key を生成
    @event.event_key = SecureRandom.urlsafe_base64(8)

    if @event.save
      redirect_to edit_timetable_url(@event.event_key), notice: "イベントを作成しました"
    else
      # 保存に失敗したら new を再表示（validation メッセージを @event に持たせる）
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    @page_title = "イベント情報編集"
  end

  def update
    # フォームで受け取るタグ名（nested attributes の id は無視）
    tag_name = params.dig(:event, :event_name_tag_attributes, :name)&.strip

    # タグ名が空ならエラーにする
    if tag_name.blank?
      @event.build_event_name_tag(name: tag_name) unless @event.event_name_tag
      @event.event_name_tag.errors.add(:name, :blank)
      @event.errors.add(:base, @event.event_name_tag.errors.full_messages.first)
      return render :edit, status: :unprocessable_entity
    end

    # 既存のタグは更新せず、新しいタグに置き換える
    @event.event_name_tag = EventNameTag.find_or_create_by!(name: tag_name)

    # Event 本体を更新（description など）
    if @event.update(event_params.except(:event_name_tag_attributes))
      redirect_to edit_event_path(@event.event_key), notice: "イベントを更新しました"
    else
      render :edit, status: :unprocessable_entity
    end
  end

  # 削除処理
  def destroy
    @event.destroy!
    redirect_to events_path, notice: "イベントを削除しました"
  end

  private

  # ログインユーザーが持つイベントのみ取得するフィルタ（見つからない場合は404エラー）
  def set_event
    @event = current_user.events.find_by!(event_key: params[:event_key])
  end

  # 許可するパラメーター
  def event_params
    params.require(:event).permit(
      :description,
      event_name_tag_attributes: [ :name ] # event_name_tagに対するエラーの伝播を許可
    )
  end
end
