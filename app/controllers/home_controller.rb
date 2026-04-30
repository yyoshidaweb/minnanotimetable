class HomeController < ApplicationController
  def index
      future = Event.future_all.limit(10).to_a
      remaining_size = 10 - future.size
      past = remaining_size > 0 ? Event.past_all.limit(remaining_size).to_a : []
      @events = (future + past)
    if user_signed_in?
      @created_events = Event.recent_created_for_home(current_user)
      @favorite_events = Event.recent_favorite_for_home(current_user)
    end
  end
end
