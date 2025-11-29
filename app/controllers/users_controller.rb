class UsersController < ApplicationController
  def show
    @user = User.find_by!(username: params[:username])
    @page_title = @user.name
  end
end
