class Performance < ApplicationRecord
  before_save :calculate_duration

  belongs_to :performer
  belongs_to :day, optional: true
  belongs_to :stage, optional: true

  validate :end_time_after_start_time, if: -> { start_time && end_time }

  # 5分刻みであることをチェック
  validate :time_must_be_5min_step

  # hour/minute フォームの入力に基づくバリデーション
  validate :start_time_complete, if: -> { start_time_hour_or_minute_present? }
  validate :end_time_complete, if: -> { end_time_hour_or_minute_present? }

  # イベントに紐づく出演者を取得し、出演者ごとにまとめて出演情報を取得するスコープ
  scope :for_event, ->(event) {
    joins(:performer)
      .where(performers: { event_id: event.id })
  }

  attr_accessor :start_time_hour, :start_time_minute, :end_time_hour, :end_time_minute

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

  # 5分刻みであることをチェック
  def time_must_be_5min_step
    if start_time && start_time.min % 5 != 0
      errors.add(:start_time, "は5分刻みで入力してください")
    end
    if end_time && end_time.min % 5 != 0
      errors.add(:end_time, "は5分刻みで入力してください")
    end
  end

  def start_time_hour_or_minute_present?
    start_time_hour.present? || start_time_minute.present?
  end

  def end_time_hour_or_minute_present?
    end_time_hour.present? || end_time_minute.present?
  end

  def start_time_complete
    if start_time_hour.blank? || start_time_minute.blank?
      errors.add(:start_time, "を正しく指定するか、未定のままにしてください")
    end
  end

  def end_time_complete
    if end_time_hour.blank? || end_time_minute.blank?
      errors.add(:end_time, "を正しく指定するか、未定のままにしてください")
    end
  end
end
