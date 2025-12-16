class Performance < ApplicationRecord
  before_save :calculate_duration

  belongs_to :performer
  belongs_to :day, optional: true
  belongs_to :stage, optional: true

  validate :end_time_after_start_time, if: -> { start_time && end_time }
  # 時刻が不完全ではないことをチェック
  validate :time_must_be_fully_selected

  # 5分刻みであることをチェック
  validate :time_must_be_5min_step

  # イベントに紐づく出演者を取得し、出演者ごとにまとめて出演情報を取得するスコープ
  scope :for_event, ->(event) {
    joins(:performer)
      .where(performers: { event_id: event.id })
  }

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

  # 時刻が不完全ではないことをチェック
  def time_must_be_fully_selected
    # start_time が部分指定されている場合
    if start_time_before_type_cast.present? && start_time.nil?
      errors.add(:start_time, "は時刻を正しく指定するか、未定のままにしてください")
    end
    # end_time が部分指定されている場合
    if end_time_before_type_cast.present? && end_time.nil?
      errors.add(:end_time, "は時刻を正しく指定するか、未定のままにしてください")
    end
  end

  # 5分刻みであることをチェック
  def time_must_be_5min_step
    if start_time && start_time.min % 5 != 0
      errors.add(:start_time, "は5分刻みで入力してください")
    end
    if end_time && end_time.min % 5 != 0
      errors.add(:end_time, "は5分刻みで入力してください")
    end
  end
end
