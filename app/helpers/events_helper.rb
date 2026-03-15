module EventsHelper
  # event-headerの色のクラスを返す
  def event_header_color
    @my_timetable_view ? "bg-orange-600" : "bg-gray-800"
  end

  # event-headerのタイトルを返す
  def event_header_title
    if @my_timetable_view
      "#{@user.name}の#{@event.display_name} マイタイムテーブル"
    else
      "#{@event.display_name} タイムテーブル"
    end
  end
end
