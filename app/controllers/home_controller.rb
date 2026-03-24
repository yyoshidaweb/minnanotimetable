class HomeController < ApplicationController
  def index
    @events = Event.popular_for_home
    if user_signed_in?
      @created_events = Event.recent_created_for_home(current_user)
      @favorite_events = Event.recent_favorite_for_home(current_user)
    end
  end
end
