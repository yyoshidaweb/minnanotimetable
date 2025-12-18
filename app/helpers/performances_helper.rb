module PerformancesHelper
  # 5分刻みの時刻スロットを生成
  def time_select_options(hour_step: 1, minute_step: 5, start_hour: 0, end_hour: 24)
    {
      hours: (start_hour...end_hour).step(hour_step).map { |h| [ format("%02d", h), h ] },
      minutes: (0...60).step(minute_step).map { |m| [ format("%02d", m), m ] }
    }
  end
end
