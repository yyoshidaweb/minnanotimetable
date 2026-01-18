class TimetablesController < ApplicationController
  # イベントをセット
  before_action :set_event
  # 所有者本人のみアクセス可能
  before_action :authorize_event!, only: %i[ edit ]
  # === 出演者、開催日、ステージをセット ===
  before_action :set_performers, only: %i[ show edit ]
  before_action :set_days, only: %i[ show edit ]
  before_action :set_stages, only: %i[ show edit ]
  # 選択された開催日をセット
  before_action :set_selected_date, only: %i[ show edit ]
  # タイムテーブル描画に必要な情報がすべて揃った performance を取得
  before_action :set_timetable_ready_for_event_on_date, only: %i[ show edit ]
  # ステージと出演情報を事前にグループ化しておく（@performances_by_stage[stage.id]で取得可能）
  before_action :performances_by_stage, only: %i[ show edit ]
  # ビュー上でパフォーマンスを素早く検索できるようにHash化しておく
  before_action :set_performance_map, only: %i[ show edit ]

  def show
    # ヘッダー非表示フラグ
    @hidden_header = true
    # マージン不要フラグ
    @no_margin = true
    # イベント用ヘッダー表示フラグ
    @show_event_header = true
  end

  private
    # イベントを取得
    def set_event
      @event = Event.includes(:event_name_tag).find_by!(event_key: params[:event_key])
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
      @stages = @event.stages.includes(:stage_name_tag)
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
end
