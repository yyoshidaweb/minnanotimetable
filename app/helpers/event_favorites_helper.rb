module EventFavoritesHelper
  # お気に入りタイムテーブルidを取得
  def event_favorite_id(event)
    current_user.favorite_event_id(event)
  end
end
