class PerformerNameTagsController < ApplicationController
  def search
    query = params[:query].to_s
    @tags = PerformerNameTag
              .popular
              .where("LOWER(name) LIKE ?", "%#{query.downcase}%")
              .limit(5)

    render partial: "performer_name_tags/suggestions",
          formats: :turbo_stream,
          locals: { tags: @tags }
  end
end
