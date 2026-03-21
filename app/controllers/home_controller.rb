class HomeController < ApplicationController
  def index
    @events = Event.popular_for_home
  end
end
