class PerformerFavoritesController < ApplicationController
  # ユーザがログインしているかどうかを確認し、ログインしていない場合はユーザをログインページにリダイレクトする。
  before_action :authenticate_user!

  # 出演者お気に入り登録実行
  def create
    performer = Performer.find(params[:performer_id])
    current_user.performer_favorites.create!(performer: performer)
    # 登録後は元のページにリダイレクトする（もし元のページが不明の場合はトップページにリダイレクトする）
    redirect_back fallback_location: root_path, notice: "出演者をお気に入りに登録しました。"
  end

  # 出演者お気に入り登録解除実行
  def destroy
    favorite = current_user.performer_favorites.find(params[:id])
    favorite.destroy!
    # 解除後は元のページにリダイレクトする（もし元のページが不明の場合はトップページにリダイレクトする）
    redirect_back fallback_location: root_path, notice: "出演者をお気に入りから解除しました。"
  end

  private
    # 許可するパラメーター
    def performer_favorite_params
      params.fetch(:performer_favorite, {})
    end
end
