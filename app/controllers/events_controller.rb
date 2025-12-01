class EventsController < ApplicationController
  def show
    # event_key でイベントを取得
    @event = Event.find_by!(event_key: params[:event_key])

    # 関連データをまとめて取得（必要に応じて）
    @days = @event.days.order(:date)
    @performers = @event.performers
    @stages = @event.stages
    @page_title = @event.event_name_tag.name
  end
end
