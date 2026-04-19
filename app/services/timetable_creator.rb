# JSON形式のタイムテーブルデータから、Stage、Performer、Performanceを作成するサービスクラス
class TimetableCreator
  def self.create_from_json(json:, event:, day:)
    new(json, event, day).create
  end

  # 初期化
  def initialize(json, event, day)
    @json = json
    @event = event
    @day = day
  end

  # タイムテーブル作成処理
  def create
    stages = @json["stages"]
    # stagesが空の場合はエラーを返す
    return timetable_not_recognized_response if stages.blank?
    # performanceが空の場合はエラーを返す
    return timetable_not_recognized_response unless has_performance?(stages)
    ActiveRecord::Base.transaction do
      # 選択された開催日の既存のperformanceを削除
      existing_performances = Performance.where(day: @day)
      existing_performances.destroy_all
      stages.each_with_index do |stage_data, index|
        stage = find_or_create_stage(stage_data, index)
        performances = build_performances(stage, stage_data)
        calculate_durations(performances)
      end
    end
    { success: true }
  rescue StandardError => e
    Rails.logger.error(e)
    { success: false, error: "タイムテーブルの作成に失敗しました" }
  end

  private

  # stageを作成（すでに存在する場合はそれを返す）
  def find_or_create_stage(stage_data, index)
    tag = StageNameTag.find_or_create_by!(
      name: stage_data["stage_name"]
    )
    Stage.find_or_create_by!(
      event: @event,
      stage_name_tag: tag
    ) do |stage|
      stage.position = index + 1
    end
  end

  # performerを作成（すでに存在する場合はそれを返す）
  def find_or_create_performer(performance_data)
    tag = PerformerNameTag.find_or_create_by!(
      name: performance_data["performer_name"]
    )
    Performer.find_or_create_by!(
      event: @event,
      performer_name_tag: tag
    )
  end

  # performanceを一旦すべて作成して配列で返す
  def build_performances(stage, stage_data)
    temp_duration = 5
    stage_data["performances"].map do |performance_data|
      performer = find_or_create_performer(performance_data)
      Performance.find_or_create_by!(
        performer: performer,
        stage: stage,
        day: @day,
        start_time: performance_data["start_time"],
        duration: temp_duration
      )
    end.sort_by(&:start_time)
  end

  # durationを計算
  def calculate_durations(performances)
    performances.each_with_index do |performance, index|
      duration =
        if index == performances.size - 1
          performances[index - 1]&.duration || 30
        else
          calc_duration(performance.start_time, performances[index + 1].start_time)
        end
      performance.update!(duration: duration)
    end
  end

  # duration計算ロジック
  def calc_duration(current_time, next_time)
    minutes = ((next_time - current_time) / 60).to_i
    duration = minutes / 2
    duration = (duration / 5) * 5
    duration = duration.clamp(5, 60)
    duration
  end

  # タイムテーブルを認識できないエラー時のレスポンス
  def timetable_not_recognized_response
    { success: false, error: "タイムテーブルを認識できませんでした" }
  end

  # stageにperformanceが存在するかを返す
  def has_performance?(stages)
    stages.any? do |stage|
      stage["performances"].present?
    end
  end
end
