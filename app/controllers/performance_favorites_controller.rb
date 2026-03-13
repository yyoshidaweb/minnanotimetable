class PerformanceFavoritesController < ApplicationController
  # ユーザがログインしているかどうかを確認し、ログインしていない場合はユーザをログインページにリダイレクトする。
  before_action :authenticate_user!

  # 出演情報お気に入り登録実行
  def create
    performance = Performance.find(params[:performance_id])
    current_user.performance_favorites.create!(performance: performance)
    # 登録後は元のページにリダイレクトする（もし元のページが不明の場合はトップページにリダイレクトする）
    redirect_back fallback_location: root_path
  end

  # 出演情報お気に入り登録解除実行
  def destroy
    favorite = current_user.performance_favorites.find(params[:id])
    favorite.destroy!
    # 解除後は元のページにリダイレクトする（もし元のページが不明の場合はトップページにリダイレクトする）
    redirect_back fallback_location: root_path
  end
end
