class TimetablesController < ApplicationController
  # ログイン必須、かつ作成者本人であることをチェック
  before_action :authorize_event_creator!, only: [ :edit ]

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
