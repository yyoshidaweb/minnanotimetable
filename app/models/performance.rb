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
  validate :duration_at_most_one_hundred_twenty, if: -> { start_time && duration }

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

  # 6時起点の開催日内の開始時刻順
  scope :ordered_by_festival_start_time, -> {
    order(FestivalTime.wrap_order_sql, "performances.start_time ASC")
  }

  # 開催日順のあと、6時起点の開始時刻順
  # daysをJOINすると、Eventがperformers経由でperformancesをJOINしたときに
  # daysテーブル名が衝突するため、相関サブクエリで日付を参照する
  scope :ordered_by_festival_day_and_time, -> {
    order(
      Arel.sql("(SELECT days.date FROM days WHERE days.id = performances.day_id) IS NULL ASC"),
      Arel.sql("(SELECT days.date FROM days WHERE days.id = performances.day_id) ASC")
    )
      .ordered_by_festival_start_time
  }

  # 開催日と開始時刻順で並べ、必要な関連も事前ロードするスコープ
  scope :ordered_for_performer_detail, -> {
    ordered_by_festival_day_and_time.includes(:day, stage: :stage_name_tag)
  }

  # タイムテーブル描画に必要な情報がすべて揃ったperformance
  # （出演日・ステージ・開始時刻・終了時刻・出演時間がすべて存在する）
  scope :timetable_ready, -> {
    joins(:day, :stage)
      .where.not(start_time: nil)
      .where.not(end_time: nil)
      .where.not(duration: nil)
  }

  # タイムテーブル描画に必要な情報がすべて揃ったperformanceを取得するスコープ
  scope :timetable_ready_for_event_on_date, ->(event, date) {
    timetable_ready
      .joins(:performer)
      .where(performers: { event_id: event.id })
      .where(days: { date: date })
      .includes(performer: :performer_name_tag)
      .ordered_by_festival_start_time
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

  # 開始時刻をフェス日内の分単位のキーに変換（並び・位置計算用）
  def start_key
    festival_start_minutes
  end

  # 開始時刻のフェス分
  def festival_start_minutes
    FestivalTime.to_minutes(start_time)
  end

  # 終了時刻のフェス分（日付またぎを含む）
  def festival_end_minutes
    FestivalTime.end_minutes(start_time, end_time)
  end

  # hh:mm 形式の開始時刻
  def formatted_start_time
    FestivalTime.format_clock(start_time)
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

  # セレクトの上限（120分）を超えていないかチェック
  def duration_at_most_one_hundred_twenty
    errors.add(:duration, "は120以下で入力してください") if duration > 120
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
    return unless performer.present?
    return if start_time.blank? || end_time.blank?
    return if day.blank? || stage.blank?
    others = Performance
      .joins(:performer)
      .where(performers: { event_id: performer.event_id })
      .where(day_id: day_id, stage_id: stage_id)
      .where.not(id: id)
      .where.not(start_time: nil, end_time: nil)

    if others.any? { |other| festival_ranges_overlap?(other) }
      errors.add(:base, "同じ時間帯に他の出演情報が存在します")
    end
  end

  # フェス分の半開区間で重なっているか
  def festival_ranges_overlap?(other)
    festival_start_minutes < other.festival_end_minutes &&
      festival_end_minutes > other.festival_start_minutes
  end
end
