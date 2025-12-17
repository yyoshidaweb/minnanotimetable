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
  end

  def create
    @performance = Performance.new(performance_params)
    if @performance.save
      redirect_to edit_timetable_path(@event.event_key), notice: "出演情報を作成しました。"
    else
      render :new, status: :unprocessable_entity
    end
  end

  # GET /performances/1/edit
  def edit
  end

  # PATCH/PUT /performances/1 or /performances/1.json
  def update
    respond_to do |format|
      if @performance.update(performance_params)
        format.html { redirect_to @performance, notice: "Performance was successfully updated.", status: :see_other }
        format.json { render :show, status: :ok, location: @performance }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @performance.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /performances/1 or /performances/1.json
  def destroy
    @performance.destroy!

    respond_to do |format|
      format.html { redirect_to performances_path, notice: "Performance was successfully destroyed.", status: :see_other }
      format.json { head :no_content }
    end
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

    # 許可するパラメーター
    def performance_params
      params.require(:performance).permit(
        :performer_id,
        :day_id,
        :stage_id,
        :start_time,
        :end_time
      )
    end
end
