class PreviewSessionsController < ApplicationController
  # プレビュー環境でログインする
  def create
    # プレビュー環境でなければ403 Forbiddenを返すだけで何もしない
    return head :forbidden unless preview_environment?
    user = User.find_by(email: "user1@example.com")
    sign_in(user) if user
    redirect_to root_path, notice: "プレビューユーザーとしてログインしました"
  end
end
