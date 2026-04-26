class TimetablesController < ApplicationController
  # イベントをセット
  before_action :set_event, only: %i[ show new create ]
  # イベントの所有者本人のみアクセス可能
  before_action :authorize_event!, only: %i[ new create ]
  # === 出演者、開催日、ステージをセット ===
  before_action :set_performers, only: %i[ show ]
  before_action :set_days
  before_action :set_stages, only: %i[ show ]
  # 選択された開催日をセット
  before_action :set_selected_date, only: %i[ show ]
  # タイムテーブル描画に必要な情報がすべて揃った performance を取得
  before_action :set_timetable_ready_for_event_on_date, only: %i[ show ]
  # ステージと出演情報を事前にグループ化しておく（@performances_by_stage[stage.id]で取得可能）
  before_action :performances_by_stage, only: %i[ show ]
  # ビュー上でパフォーマンスを素早く検索できるようにHash化しておく
  before_action :set_performance_map, only: %i[ show ]
  before_action :set_remaining_ai_timetable_count, only: %i[ new create ]
  before_action :event_has_performances?, only: %i[ new create ]
  # ページタイトルを設定
  before_action :set_page_title
  # イベントヘッダー表示フラグ
  before_action :show_event_header
  before_action :set_form_type, only: %i[ new create ]
  before_action :set_selected_date_for_form, only: %i[ create ]

  def new
  end

  def show
    @timetable_view = true
    # イベント用ヘッダー表示フラグ
    @show_event_header = true
    # お気に入り登録している出演情報IDの配列を取得
    if user_signed_in?
      @favorite_performance_map =
        current_user.favorite_performance_map_by_performances(@performances)
    end
  end

  # 画像からタイムテーブルを作成
  def create
    # AIタイムテーブル機能の利用可能か判定
    unless current_user.ai_timetable_available?
      @event.errors.add(:base, "今月の使用回数の上限に達しました")
      render :new, status: :unprocessable_entity
      return
    end
    if params[:image].blank?
      @event.errors.add(:base, "画像を選択してください")
      render :new, status: :unprocessable_entity
      return
    end
    day = @event.days.find_by(id: params[:day_id])
    unless day
      @event.errors.add(:base, "開催日を選択してください")
      render :new, status: :unprocessable_entity
      return
    end
    file = params[:image]
    # ファイルのMIMEタイプを取得
    mime_type = Marcel::MimeType.for(file.tempfile)
    # 許可するファイルタイプ
    allowed_types = [ "image/png", "image/jpeg" ]
    # 許可されたタイプであることを確認
    unless allowed_types.include?(mime_type)
      @event.errors.add(:base, "JPEG, PNG形式のみアップロード可能です")
      render :new, status: :unprocessable_entity
      return
    end
    # AIでJSON抽出
    extract_result = TimetableExtractor.extract(file.tempfile)
    unless extract_result[:success]
      @event.errors.add(:base, extract_result[:error])
      render :new, status: :unprocessable_entity
      return
    end
    # タイムテーブル作成
    create_result = TimetableCreator.create_from_json(json: extract_result[:data], event: @event, day: day)
    unless create_result[:success]
      @event.errors.add(:base, create_result[:error])
      render :new, status: :unprocessable_entity
      return
    end
    redirect_to show_timetable_path(@event.event_key, d: day.date), notice: "タイムテーブルを作成しました"
  end

  private
    # イベントを取得
    def set_event
      event_key_param =
        if action_name == "show"
          params[:event_key]
        else
          params[:event_event_key]
        end
      @event = Event.includes(:event_name_tag).find_by!(event_key: event_key_param)
    end

    # イベントの所有者かどうかチェック（異なる場合は404エラーを発生させる）
    def authorize_event!
      raise ActiveRecord::RecordNotFound unless @event.user == current_user
    end

    # 出演者を取得
    def set_performers
      @performers = @event.performers.includes(:performer_name_tag).order_by_name
    end

    # 開催日を取得
    def set_days
      @days = @event.days.order(:date)
    end

    # ステージを取得
    def set_stages
      @stages = @event.stages.order(:position).includes(:stage_name_tag)
    end

    # 選択された開催日をセット
    def set_selected_date
      if @days.present?
        # クエリパラメータから日付を決定
        @selected_date = params[:d].present? ? Date.parse(params[:d]) : @days.first.date
      end
    end

    # タイムテーブル描画に必要な情報がすべて揃った performance を取得
    def set_timetable_ready_for_event_on_date
      @performances = Performance.timetable_ready_for_event_on_date(@event, @selected_date)
    end

    # ステージと出演情報を事前にグループ化しておく（@performances_by_stage[stage.id]で取得可能）
    def performances_by_stage
      @performances_by_stage = @performances.group_by(&:stage_id)
    end

    # ビュー上でパフォーマンスを素早く検索できるようにHash化しておく
    def set_performance_map
      @performance_map = {}
      @performances_by_stage.each do |stage_id, performances|
        @performance_map[stage_id] = performances.index_by(&:start_key)
      end
    end

    # イベントヘッダー表示フラグ
    def show_event_header
      # イベント用ヘッダー表示フラグ
      @show_event_header = true
    end

    # ページタイトルを設定
    def set_page_title
      @page_title =
        case action_name
        when "new", "create"
          "画像からタイムテーブルを作成"
        end
    end

    # form_typeをセットする
    def set_form_type
      @form_type = "timetable"
    end

    # フォームで選択されている開催日をセットする
    def set_selected_date_for_form
      return unless params[:day_id].present?
      @selected_day_id = params[:day_id]
    end

    def set_remaining_ai_timetable_count
      @remaining_ai_timetable_count = current_user.remaining_ai_timetable_count # 内部でreset_if_neededが呼ばれる
      @ai_timetable_count = current_user.ai_timetable_count
      @ai_timetable_monthly_limit = current_user.ai_timetable_monthly_limit
    end

    # イベントに出演情報があるか判定
    def event_has_performances?
      @event_has_performances = @event.performances.exists?
    end
end
