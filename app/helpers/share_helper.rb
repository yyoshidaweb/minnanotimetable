module ShareHelper
  # タイムテーブル共有用のURLを返す
  def share_event_url
    show_timetable_url(@event.event_key)
  end
end
