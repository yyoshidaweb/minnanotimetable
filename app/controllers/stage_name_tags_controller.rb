class StageNameTagsController < ApplicationController
  # ステージタグ名検索
  def search
    query = params[:query].to_s
    @tags = StageNameTag
              .popular
              .where("LOWER(name) LIKE ?", "%#{query.downcase}%")
              .limit(5)

    render partial: "stage_name_tags/suggestions",
          formats: :turbo_stream,
          locals: { tags: @tags }
  end
end
