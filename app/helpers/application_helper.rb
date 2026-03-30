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

  # text内にリンクが含まれていたら自動リンク化する
  def auto_link_text(text)
    return "" if text.blank?
    # URLをリンク化し、XSSを防ぐ
    linked = Rinku.auto_link(
      text,
      :urls,
      'target="_blank" rel="noopener"
      class="text-blue-600 underline hover:text-blue-800 break-all"'
    )
    sanitized = sanitize(
      linked,
      tags: %w[a br],
      attributes: %w[href target rel class]
    )
    content_tag(:p, sanitized.html_safe.html_safe, class: "text-gray-800 whitespace-pre-line")
  end
end
