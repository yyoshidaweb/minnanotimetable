class SessionsController < ApplicationController
  def new
    render layout: false if turbo_frame_request?
  end
end
