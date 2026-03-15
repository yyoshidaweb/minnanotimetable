module EventsHelper
  # event-headerの色のクラスを返す
  def event_header_color
    @my_timetable_view ? "bg-orange-600" : "bg-gray-800"
  end
end
