module SecondaryHeaderHelper
  # イベントヘッダーの有無によってtop位置を返す
  def secondary_header_top_position
    if defined?(@show_event_header) && @show_event_header
      "top-16"
    else
      "top-8"
    end
  end
end
