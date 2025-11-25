class ProfilesController < ApplicationController
  # ユーザがログインしているかどうかを確認し、ログインしていない場合はユーザをログインページにリダイレクトする。
  before_action :authenticate_user!

  def show
    # 現在のユーザーのプロフィールを取得
    @user = current_user
    @page_title = "プロフィール"
  end

  def edit
    @user = current_user
    @page_title = "プロフィール編集"
  end

  def update
    @user = current_user
    # プロフィールの更新
    if @user.update(user_params)
      redirect_to profile_path, notice: "プロフィールを更新しました。"
    else
      # モデルのバリデーションエラーを alert に渡す
      flash.now[:alert] = @user.errors.full_messages.join(", ")
      # 更新に失敗した場合、編集ページを再表示
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    # ユーザーアカウントの削除
    current_user.destroy
    redirect_to root_path, notice: "アカウントを削除しました。"
  end

  private

  def user_params
    # 許可されたパラメータのみを受け取る
    params.require(:user).permit(:name)
  end
end
