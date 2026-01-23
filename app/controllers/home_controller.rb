class HomeController < ApplicationController
  def index
    # イベントを新しい順で最大3件取得する
    if user_signed_in?
      @events = current_user.events.recent_for_home
    end
  end
end
