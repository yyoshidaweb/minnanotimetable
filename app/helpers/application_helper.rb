module ApplicationHelper
  # 時刻を hh:mm 形式でフォーマットして返す
  def formatted_time(time)
    time&.strftime("%H:%M")
  end


  # main要素のクラスを返す
  def main_element_class
    if defined?(@timetable_view) && @timetable_view
      ""
    elsif defined?(@show_event_header) && @show_event_header
      "m-2 pt-24"
    elsif defined?(@page_title) && @page_title.present?
      "m-2 pt-16"
    else
      "m-2 pt-8"
    end
  end
end
