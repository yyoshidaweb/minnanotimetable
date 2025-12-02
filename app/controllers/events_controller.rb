class EventsController < ApplicationController
  def show
    # event_key でイベントを取得
    @event = Event.find_by!(event_key: params[:event_key])
    # 関連データをまとめて取得
    @days = @event.days.order(:date)
    @performers = @event.performers
    @stages = @event.stages

    # クエリに ?d がある場合はそれを優先、なければ最古日付を採用
    @selected_date = params[:d].present? ? Date.parse(params[:d]) : @days.first.date

    # 対象日の performances のみ取得
    @performances = @event.performances
                          .joins(:day)
                          .where(days: { date: @selected_date })
                          .includes(:performer, :stage)
                          .order(:start_time)

    # ヘッダー非表示フラグ
    @hidden_header = true
    # マージン不要フラグ
    @no_margin = true
    # イベント用ヘッダー表示フラグ
    @show_event_header = true
  end
end
