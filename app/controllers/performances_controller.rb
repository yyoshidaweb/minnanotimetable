class PerformancesController < ApplicationController
  # イベントをセット
  before_action :set_event
  # 所有者本人のみアクセス可能
  before_action :authorize_event!
  before_action :set_performance, only: %i[ edit update destroy ]
  before_action :set_page_title, except: %i[ destroy ]

  def new
    @performance = Performance.for_event(@event).build
    @performers = @event.performers.order_by_name
    @days = @event.days.order(:date)
    @stages = @event.stages
  end

  # GET /performances/1/edit
  def edit
  end

  # POST /performances or /performances.json
  def create
    @performance = Performance.new(performance_params)

    respond_to do |format|
      if @performance.save
        format.html { redirect_to @performance, notice: "Performance was successfully created." }
        format.json { render :show, status: :created, location: @performance }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @performance.errors, status: :unprocessable_entity }
      end
    end
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
      Performance.for_event(@event).find(params[:id])
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
      )
    end
end
