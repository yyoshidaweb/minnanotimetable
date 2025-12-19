class TimetablesController < ApplicationController
  # ログイン必須、かつ作成者本人であることをチェック
  before_action :authorize_event_creator!, only: [ :edit ]

  def show
    # イベント本体と name_tag を同時に取得
    @event = Event.includes(:event_name_tag)
                .find_by!(event_key: params[:event_key])
    # 日付を古い順に取得
    @days = @event.days.order(:date)
    # performers に対して name_tag をプリロード
    @performers = @event.performers.includes(:performer_name_tag)
    # stages に対して name_tag をプリロード
    @stages = @event.stages.includes(:stage_name_tag)

    # クエリパラメータから日付を決定
    @selected_date = params[:d].present? ? Date.parse(params[:d]) : @days.first.date

    # タイムテーブル描画に必要な情報がすべて揃った performance を取得
    @performances =
      Performance.timetable_ready_for_event_on_date(@event, @selected_date)

    # ステージと出演情報を事前にグループ化しておく（@performances_by_stage[stage.id]で取得可能）
    @performances_by_stage = @performances.group_by(&:stage_id)


    # 開始時刻が最も早い出演者の出演時刻を取得
    earliest_time = @performances.min_by(&:start_time).start_time.hour
    # 終了時刻が最も遅い出演者の出演時刻を取得
    latest_end_time = @performances.max_by(&:end_time).end_time.hour
    # 時刻列用の配列を事前に作成する
    @time_slots = (earliest_time..latest_end_time).flat_map do |hour|
      (0..55).step(5).map { |minute| [ hour, minute ] }
    end

    # ヘッダー非表示フラグ
    @hidden_header = true
    # マージン不要フラグ
    @no_margin = true
    # イベント用ヘッダー表示フラグ
    @show_event_header = true
  end

  # タイムテーブル編集ページ表示
  def edit
    # 作成者チェック
    unless @event.user == current_user
      redirect_to root_path, alert: "編集権限がありません"
    end
    @days = @event.days.includes(:performances)
    @stages = @event.stages
    @performers = @event.performers
    @performances = @event.performances.includes(:day, :stage, :performer)
    @page_title = "タイムテーブル編集"
  end

  private

  def authorize_event_creator!
    @event = Event.find_by!(event_key: params[:event_key])
    redirect_to root_path, alert: "編集権限がありません" unless @event.user == current_user
  end
end
