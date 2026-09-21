class EventsController < ApplicationController
  # ログイン必須（show以外）
  before_action :authenticate_user!, only: [ :new, :create, :update ]
  before_action :authenticate_user!, only: [ :index ], if: -> { params[:filter] == "created" || params[:filter] == "favorites" }

  # イベントを取得する
  before_action :set_event, only: [ :show, :edit, :update, :destroy ]
  # 所有者本人かどうかチェック
  before_action :authorize_event!, only: [ :edit, :update, :destroy ]
  # 非公開イベントの閲覧制御
  before_action :authorize_published_event_access!, only: [ :show ]
  # 開催日を昇順で取得
  before_action :set_days, only: [ :show, :edit ]
  before_action :set_page_title, except: %i[ destroy ]
  before_action :show_event_header, except: %i[ index new create destroy ]

  # 作成したイベント一覧
  def index
    # パラメータによって取得するイベントを分岐
    case params[:filter]
    when "favorites"
      result = Event.paginate_relation(Event.recent_favorite_by(current_user), page: params[:page])
      @page_title = "お気に入りのタイムテーブル一覧"
    when "created"
      result = Event.paginate_relation(Event.recent_created_by(current_user), page: params[:page])
      @page_title = "作成したタイムテーブル一覧"
    else
      result = Event.paginate_public_all(page: params[:page])
      @show_upcoming_heading = result[:show_upcoming_heading]
      @past_index = result[:past_index]
      @without_timetable_ready_index = result[:without_timetable_ready_index]
      @page_title = "みんなが作ったタイムテーブル"
    end
    @back_path = root_path
    @back_label = "トップ"

    @events = result[:events]
    @page = result[:page]
    @next_page = result[:next_page]
  end

  # 未ログインでも閲覧可能
  def show
  end

  # イベント作成ページ表示
  def new
    @event = Event.new
    # nested form 用に空のタグオブジェクトを用意
    @event.build_event_name_tag
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
    event_name_tag = EventNameTag.find_or_initialize_by(name: tag_name)

    # タグのバリデーションチェック
    unless event_name_tag.save
      @event.build_event_name_tag(name: tag_name)
      @event.event_name_tag.errors.copy!(event_name_tag.errors) # 子モデルのエラーをコピー
      @event.errors.add(:base, event_name_tag.errors.full_messages.first)
      return render :new, status: :unprocessable_entity
    end

    # Event に紐付け
    @event.event_name_tag = event_name_tag

    # event_key を生成
    @event.event_key = SecureRandom.urlsafe_base64(8)

    if @event.save
      redirect_to show_timetable_path(@event.event_key), notice: "タイムテーブルを作成しました"
    else
      # 保存に失敗したら new を再表示（validation メッセージを @event に持たせる）
      render :new, status: :unprocessable_entity
    end
  end

  def edit
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

    # 既存タグを探す or 新規作成
    event_name_tag = EventNameTag.find_or_initialize_by(name: tag_name)

    # タグのバリデーションチェック
    unless event_name_tag.valid?
      # 入力値をフォームに残す
      @event.event_name_tag = event_name_tag
      @event.event_name_tag.errors.copy!(event_name_tag.errors)
      @event.errors.add(:base, event_name_tag.errors.full_messages.first)
      return render :edit, status: :unprocessable_entity
    end

    event_name_tag.save if event_name_tag.new_record?

    # Event に新しいタグを紐付け
    @event.event_name_tag = event_name_tag

    # Event 本体を更新（description など）
    if @event.update(event_params.except(:event_name_tag_attributes))
      redirect_to event_path(@event.event_key), notice: "タイムテーブルを更新しました"
    else
      render :edit, status: :unprocessable_entity
    end
  end

  # 削除処理
  def destroy
    @event.destroy!
    redirect_to events_path(filter: "created"), notice: "タイムテーブルを削除しました"
  end

  private

  # イベントを取得
  def set_event
    @event = Event.find_by!(event_key: params[:event_key])
  end

  # イベントの所有者かどうかチェック（異なる場合は404エラーを発生させる）
  def authorize_event!
    raise ActiveRecord::RecordNotFound unless @event.user == current_user
  end

  # 非公開イベントは作成者のみ閲覧可能
  def authorize_published_event_access!
    authorize_published_event!(@event)
  end

  # 開催日を昇順にセットする
  def set_days
    @days = @event.days.order(:date)
  end

  # ページタイトルと戻り先を設定（概要タブには戻るボタンを付けない）
  def set_page_title
    case action_name
    when "new", "create"
      @page_title = "タイムテーブルを作成"
      @back_path = events_path(filter: "created")
      @back_label = "一覧"
    when "show"
      @page_title = "概要"
    when "edit", "update"
      @page_title = "タイムテーブルを編集"
      @back_path = event_path(@event.event_key)
      @back_label = "概要"
    end
  end

  # イベントヘッダー表示フラグ
  def show_event_header
    # イベント用ヘッダー表示フラグ
    @show_event_header = true
  end

  # 許可するパラメーター
  def event_params
    params.require(:event).permit(
      :description,
      :visibility,
      event_name_tag_attributes: [ :name ] # event_name_tagに対するエラーの伝播を許可
    )
  end
end
