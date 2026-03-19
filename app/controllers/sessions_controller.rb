class SessionsController < ApplicationController
  def new
    # セッションにモーダル表示時のURLを保存
    session[:user_return_to] = request.referer
    render layout: false if turbo_frame_request?
  end
end
