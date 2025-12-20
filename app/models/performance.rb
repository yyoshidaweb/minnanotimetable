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

  # タイムテーブル描画に必要な情報がすべて揃った performance を取得するスコープ
  scope :timetable_ready_for_event_on_date, ->(event, date) {
    joins(:performer, :day, :stage)
    .where.not(
      start_time: nil,
      end_time: nil,
      duration: nil
    )
    .where(performers: { event_id: event.id })
    .where(days: { date: date })
    .includes(
      performer: :performer_name_tag,
      stage: :stage_name_tag
    )
    .order(:start_time)
  }

  # ==== タイムテーブル表示用メソッド ====

  # 開始時（hour）
  def start_h
    start_time.hour
  end

  # 開始分（minute）
  def start_m
    start_time.min
  end

  # 開始時刻を分単位のキーに変換（並び・位置計算用）
  def start_key
    start_time.hour * 60 + start_time.min
  end

  # hh:mm 形式の開始時刻
  def formatted_start_time
    format("%02d:%02d", start_time.hour, start_time.min)
  end

  # 5分単位に変換した出演時間
  def duration_in_5_min_units
    duration / 5
  end

  # 30分未満は開始時刻を表示しない
  def show_start_time?
    duration >= 30
  end

  # ==== フォーム入力用補助属性 ====

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
