class FabController < ApplicationController
  def show
    @event = Event.find_by(event_key: params[:event_key])
    render layout: false if turbo_frame_request?
  end
end
