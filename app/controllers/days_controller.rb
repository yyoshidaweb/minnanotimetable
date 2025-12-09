class DaysController < ApplicationController
  # ログイン必須
  before_action :authenticate_user!
  before_action :set_event
  before_action :set_day, only: %i[ destroy ]
  before_action :set_page_title, only: %i[ new create ]

  # 開催日追加ページ表示
  def new
    @day = @event.days.build
  end

  # 開催日追加処理
  def create
    @day = @event.days.build(day_params)

    if @day.save
      redirect_to edit_timetable_path(@event.event_key), notice: "開催日を追加しました。"
    else
      render :new, status: :unprocessable_entity
    end
  end

  # 開催日削除処理
  def destroy
    @day.destroy!
    redirect_to edit_timetable_path(@event.event_key), notice: "開催日を削除しました。", status: :see_other
  end

  private
    # ログインユーザーが持つイベントのみ取得するフィルタ（見つからない場合は404エラー）
    def set_event
      @event = current_user.events.find_by!(event_key: params[:event_event_key])
    end

    # イベントに紐づく開催日のみ取得
    def set_day
      @day = @event.days.find(params[:id])
    end

    # ページタイトルを設定
    def set_page_title
      @page_title =
        case action_name
        when "new", "create"
          "開催日を追加"
        end
    end

    # 許可するパラメーター
    def day_params
      params.require(:day).permit(:date)
    end
end
