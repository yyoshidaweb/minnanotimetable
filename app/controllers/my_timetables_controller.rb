class MyTimetablesController < ApplicationController
  # ユーザーをセット
  before_action :set_user
  # イベントをセット
  before_action :set_event
  # === 出演者、開催日、ステージをセット ===
  before_action :set_performers
  before_action :set_days
  before_action :set_stages
  # 選択された開催日をセット
  before_action :set_selected_date
  # タイムテーブル描画に必要な情報がすべて揃った performance を取得
  before_action :set_timetable_ready_for_event_on_date
  # お気に入り登録している出演情報のみに絞り込む
  before_action :filter_favorite_performances
  # ステージと出演情報を事前にグループ化しておく（@performances_by_stage[stage.id]で取得可能）
  before_action :performances_by_stage
  # ビュー上でパフォーマンスを素早く検索できるようにHash化しておく
  before_action :set_performance_map

  def show
    @timetable_view = true
    # イベント用ヘッダー表示フラグ
    @show_event_header = true
  end

  private
    # ユーザーを取得
    def set_user
      @user = User.find_by!(username: params[:username])
    end

    # イベントを取得
    def set_event
      @event = Event.includes(:event_name_tag).find_by!(event_key: params[:event_key])
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

    # お気に入り登録している出演情報のみに絞り込む
    def filter_favorite_performances
      @favorite_performance_map = @user.favorite_performance_map_by_performances(@performances)
      favorite_ids = @favorite_performance_map.keys
      @performances = @performances.where(id: favorite_ids)
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
end
