class PerformancesController < ApplicationController
  # イベントをセット
  before_action :set_event
  # 所有者本人のみアクセス可能
  before_action :authorize_event!
  # === 出演者、開催日、ステージをセット ===
  before_action :set_performers, only: %i[ new create edit update ]
  before_action :set_days, only: %i[ new create edit update ]
  before_action :set_stages, only: %i[ new create edit update ]
  # 出演情報をセット
  before_action :set_performance, only: %i[ edit update destroy ]
  # ページタイトル設定
  before_action :set_page_title, except: %i[ destroy ]

  def new
    @performance = Performance.new
    # 出演者詳細ページから遷移した場合は出演者をセットする
    if params[:performer_id].present?
      @performance.performer_id = params[:performer_id]
    end
  end

  def create
    @performance = Performance.new(performance_params_for_create)
    if @performance.save
      redirect_to show_timetable_path(@event.event_key), notice: "出演情報を作成しました。"
    else
      # エラー時に select の選択値を保持する
      restore_time_virtual_attributes
      render :new, status: :unprocessable_entity
    end
  end


  def edit
    @performance.start_time_hour   = @performance.start_time&.hour
    @performance.start_time_minute = @performance.start_time&.min
    @performance.end_time_hour     = @performance.end_time&.hour
    @performance.end_time_minute   = @performance.end_time&.min
  end

  def update
    if @performance.update(performance_params_for_update)
      redirect_to event_performer_url(@event.event_key, @performance.performer), notice: "出演情報を更新しました。"
    else
      restore_time_virtual_attributes
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @performance.destroy!
    redirect_to event_performer_url(@event.event_key, @performance.performer), notice: "出演情報を削除しました。", status: :see_other
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

    # 出演情報を取得
    def set_performance
      @performance = Performance.for_event(@event).find(params[:id])
    end

    # 出演者を取得
    def set_performers
      @performers = @event.performers.order_by_name
    end

    # 開催日を取得
    def set_days
      @days = @event.days.order(:date)
    end

    # ステージを取得
    def set_stages
      @stages = @event.stages
    end

    # ページタイトルを設定
    def set_page_title
      @page_title =
        case action_name
        when "new", "create"
          "出演情報を作成"
        when "show"
          "出演情報詳細"
        when "edit", "update"
          "出演情報を編集"
        end
    end

    # create時に許可するパラメーター
    def performance_params_for_create
      params.require(:performance).permit(
        :performer_id,
        :day_id,
        :stage_id,
        :start_time_hour,
        :start_time_minute,
        :end_time_hour,
        :end_time_minute
      ).tap do |p|
        # hour / minute から Time を組み立てる
        p[:start_time] = parse_time_from_hour_minute(
          p[:start_time_hour],
          p[:start_time_minute]
        )
        p[:end_time] = parse_time_from_hour_minute(
          p[:end_time_hour],
          p[:end_time_minute]
        )
      end
    end

    # update時に許可するパラメーター
    def performance_params_for_update
      params.require(:performance).permit(
        :day_id,
        :stage_id,
        :start_time_hour,
        :start_time_minute,
        :end_time_hour,
        :end_time_minute
      ).tap do |p|
        # hour / minute から Time を組み立てる
        p[:start_time] = parse_time_from_hour_minute(
          p[:start_time_hour],
          p[:start_time_minute]
        )
        p[:end_time] = parse_time_from_hour_minute(
          p[:end_time_hour],
          p[:end_time_minute]
        )
      end
    end

    # 時刻をhourとminuteから作成
    def parse_time_from_hour_minute(hour, minute)
      return nil if hour.blank? || minute.blank?
      Time.zone.local(2000, 1, 1, hour.to_i, minute.to_i)
    end

    def restore_time_virtual_attributes
      return unless params[:performance]
      @performance.start_time_hour   = params[:performance][:start_time_hour]
      @performance.start_time_minute = params[:performance][:start_time_minute]
      @performance.end_time_hour     = params[:performance][:end_time_hour]
      @performance.end_time_minute   = params[:performance][:end_time_minute]
    end
end
