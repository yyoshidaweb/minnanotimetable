class Performance < ApplicationRecord
  # 出演情報を削除すると、紐づいているお気に入りも全て削除される
  has_many :performance_favorites, dependent: :destroy
  # 出演情報をお気に入り登録しているユーザーの一覧を取得したいときに使うエイリアス
  has_many :favorited_users, through: :performance_favorites, source: :user

  before_validation :calculate_end_time

  belongs_to :performer
  belongs_to :day, optional: true
  belongs_to :stage, optional: true

  validate :duration_more_five, if: -> { start_time && duration }

  # 5分刻みであることをチェック
  validate :time_must_be_5min_step

  # hour/minute フォームの入力に基づくバリデーション
  validate :start_time_complete, if: -> { start_time_hour_or_minute_present? }
  validate :duration_present_if_start_time_present
  validate :start_time_present_if_duration_present
  # 出演時間重複防止
  validate :time_range_must_not_overlap

  # イベントに紐づく出演者を取得し、出演者ごとにまとめて出演情報を取得するスコープ
  scope :for_event, ->(event) {
    joins(:performer)
      .where(performers: { event_id: event.id })
  }

  # 開催日と開始時刻順で並べ、必要な関連も事前ロードするスコープ
  scope :ordered_for_performer_detail, -> {
    left_joins(:day)
      .includes(:day, :stage)
      .order(
        Arel.sql("days.date IS NULL ASC"), # dayあり → dayなし の順
        "days.date ASC",
        "performances.start_time ASC"
      )
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

  attr_accessor :start_time_hour, :start_time_minute

  private

  # start_time + duration から end_time を計算
  def calculate_end_time
    # start_time またはdurationが未入力ならend_timeもnilにする
    if start_time.blank? || duration.blank?
      self.end_time = nil
      return
    end
    minutes = duration.to_i
    self.end_time = start_time + minutes.minutes
  end

  # durationが5以上かチェック
  def duration_more_five
    errors.add(:duration, "は5以上で入力してください") if duration < 5
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

  def start_time_complete
    if start_time_hour.blank? || start_time_minute.blank?
      errors.add(:start_time, "を正しく指定するか、未定のままにしてください")
    end
  end

  # start_timeがある場合はduration必須
  def duration_present_if_start_time_present
    if start_time.present? && duration.blank?
      errors.add(:duration, "を入力してください")
    end
  end

  # durationがある場合はstart_time必須
  def start_time_present_if_duration_present
    if duration.present? && start_time.blank?
      errors.add(:start_time, "を入力してください")
    end
  end

  # 同じイベント・同じ日・同じステージで時間が重複していないかチェック
  def time_range_must_not_overlap
    return if start_time.blank? || end_time.blank?
    return if day.blank? || stage.blank?
    overlapping = Performance
      .joins(:performer)
      .where(performers: { event_id: performer.event_id })
      .where(day_id: day_id, stage_id: stage_id)
      .where.not(id: id)
      .where(
        "start_time < ? AND end_time > ?",
        end_time,
        start_time
      )

    if overlapping.exists?
      errors.add(:base, "同じ時間帯に他の出演情報が存在します")
    end
  end
end
