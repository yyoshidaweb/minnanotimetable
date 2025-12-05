class EventNameTagsController < ApplicationController
  # イベントタグ名検索
  def search
    query = params[:query].to_s
    @tags = EventNameTag
              .where("LOWER(name) LIKE ?", "%#{query.downcase}%")
              .limit(5)

    render partial: "event_name_tags/suggestions",
          formats: :turbo_stream,
          locals: { tags: @tags }
  end
end
