class Performance < ApplicationRecord
  before_save :calculate_duration

  belongs_to :performer
  belongs_to :day, optional: true
  belongs_to :stage, optional: true

  validate :end_time_after_start_time, if: -> { start_time && end_time }

  private

  # durationを計算して保存する
  def calculate_duration
    # start / end がどちらか欠けていれば何もしない
    return unless start_time && end_time
    self.duration = ((end_time - start_time) / 60).to_i # 分単位
  end

  # 出演終了時刻が正しいことをチェック
  def end_time_after_start_time
    errors.add(:end_time, "は開始時刻より後にしてください") if end_time <= start_time
  end
end
