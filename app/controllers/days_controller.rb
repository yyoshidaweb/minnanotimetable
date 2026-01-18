class DaysController < ApplicationController
  # ログイン必須
  before_action :authenticate_user!
  before_action :set_event
  # 所有者本人かどうかチェック
  before_action :authorize_event!
  before_action :set_day, only: %i[ destroy ]
  before_action :set_page_title, only: %i[ index new create ]
  before_action :show_event_header, except: %i[ destroy ]

  # 開催日の追加と削除を行うページ
  def index
    @days = @event.days.order(:date)
  end

  # 開催日追加ページ表示
  def new
    @day = @event.days.build
  end

  # 開催日追加処理
  def create
    @days = @event.days.order(:date)
    @day = @event.days.build(day_params)

    if @day.save
      respond_to do |format|
        format.turbo_stream
        format.html { redirect_to event_days_path(@event.event_key), notice: "開催日を追加しました。" }
      end
    else
      render :new, status: :unprocessable_entity
    end
  end

  # 開催日削除処理
  def destroy
    @day.destroy!
    redirect_to event_days_path(@event.event_key), notice: "開催日を削除しました。", status: :see_other
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

    # イベントに紐づく開催日のみ取得
    def set_day
      @day = @event.days.find(params[:id])
    end

    # ページタイトルを設定
    def set_page_title
      @page_title =
        case action_name
        when "index"
          "開催日一覧"
        when "new", "create"
          "開催日を追加"
        end
    end

    # イベントヘッダー表示フラグ
    def show_event_header
      # イベント用ヘッダー表示フラグ
      @show_event_header = true
    end

    # 許可するパラメーター
    def day_params
      params.require(:day).permit(:date)
    end
end
