class UsersController < ApplicationController
  def show
    @user = User.find_by!(username: params[:username])
    @page_title = "ユーザー詳細"
  end
end
