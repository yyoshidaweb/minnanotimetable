module ApplicationHelper
  # 時刻を hh:mm 形式でフォーマットして返す
  def formatted_time(time)
    time&.strftime("%H:%M")
  end
end
