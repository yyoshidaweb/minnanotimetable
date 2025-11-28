class UsersController < ApplicationController
  def show
    @user = User.find_by!(user_id: params[:user_id])
    @page_title = @user.name
  end
end
