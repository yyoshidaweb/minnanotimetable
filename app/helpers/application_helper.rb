module ApplicationHelper
  # 与えられた時刻を5分単位で切り上げる
  # @param time [Time] 切り上げ対象の時刻
  # @return [Time] 5分単位で切り上げられた時刻
  def ceil_to_nearest_5_minutes(time)
    minutes = time.min
    if minutes % 5 != 0
      minutes = ((minutes / 5.0).ceil * 5)
    end
    time.change(min: minutes)
  end

  # 分をタイムテーブルの行数（rem単位）に変換する
  # 5分 = 1.0remとして計算（以前は0.75rem）
  # @param minutes [Integer] 変換する分数
  # @return [Float] 行数（rem単位）
  def duration_to_rows(minutes)
    (minutes / 5.0) * 1.0  # 0.75から1.0に変更
  end

  # アーティストの表示位置と高さを計算
  # @param artist [Artist] 表示するアーティスト
  # @return [Hash] top: 表示開始位置, height: 表示の高さ（rem単位）
  def artist_display_props(artist)
    start_time = ceil_to_nearest_5_minutes(artist.start_time)
    end_time = ceil_to_nearest_5_minutes(artist.end_time)
    duration_minutes = ((end_time - start_time) / 60).to_i

    {
      top: duration_to_rows((start_time.hour - 10) * 60 + start_time.min),
      height: duration_to_rows(duration_minutes)
    }
  end

  # 認証状態を確認（開発用の仮実装）
  # @return [Boolean] 認証状態
  def authenticated?
    true
  end
end
