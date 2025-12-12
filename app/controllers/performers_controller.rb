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

  def edit
  end

  def create
    @performer = Performer.new(performer_params)

    respond_to do |format|
      if @performer.save
        format.html { redirect_to @performer, notice: "Performer was successfully created." }
        format.json { render :show, status: :created, location: @performer }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @performer.errors, status: :unprocessable_entity }
      end
    end
  end

  def update
    respond_to do |format|
      if @performer.update(performer_params)
        format.html { redirect_to @performer, notice: "Performer was successfully updated.", status: :see_other }
        format.json { render :show, status: :ok, location: @performer }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @performer.errors, status: :unprocessable_entity }
      end
    end
  end

  def destroy
    @performer.destroy!

    respond_to do |format|
      format.html { redirect_to performers_path, notice: "Performer was successfully destroyed.", status: :see_other }
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
