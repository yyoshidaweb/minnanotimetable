class EventsController < ApplicationController
  # ヘルパーを呼ぶ
  include EventsHelper

  # ログイン必須（show以外）
  before_action :authenticate_user!, only: [ :new, :create ]

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

  def show
    @event = Event.includes(:event_name_tag).find_by!(event_key: params[:event_key])

    timetable_data = prepare_event_timetable(@event, selected_date: params[:d]&.then { |d| Date.parse(d) })

    # ハッシュをインスタンス変数に展開
    timetable_data.each { |k, v| instance_variable_set("@#{k}", v) }

    @hidden_header = true
    @no_margin = true
    @show_event_header = true
  end

  private

  # 許可するパラメーター
  def event_params
    params.require(:event).permit(
      :description,
      event_name_tag_attributes: [ :name ] # event_name_tagに対するエラーの伝播を許可
    )
  end
end
