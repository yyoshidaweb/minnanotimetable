class HomeController < ApplicationController
  def index
    if user_signed_in?
      @events = current_user.events
                            .order(created_at: :desc)
                            .limit(3) # 表示は最大3件まで
    end
  end
end
