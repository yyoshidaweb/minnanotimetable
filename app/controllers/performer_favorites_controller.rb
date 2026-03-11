class PerformerFavoritesController < ApplicationController
  before_action :authenticate_user!

  # performerに紐づく全performanceを一括お気に入り登録
  def create
    performer = Performer.find(params[:performer_id])
    performer.performances.find_each do |performance|
      current_user.performance_favorites.find_or_create_by!(performance: performance)
    end
    redirect_back fallback_location: root_path, notice: "お気に入りに登録しました。"
  end

  # performerに紐づく全performanceを解除
  def destroy
    performer = Performer.find(params[:performer_id])
    performances = performer.performances.pluck(:id)
    current_user.performance_favorites
                .where(performance_id: performances)
                .destroy_all
    redirect_back fallback_location: root_path, notice: "お気に入りを解除しました。"
  end
end
