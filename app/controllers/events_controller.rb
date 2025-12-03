class EventsController < ApplicationController
  def show
    # イベント本体と name_tag を同時に取得
    @event = Event.includes(:event_name_tag)
                .find_by!(event_key: params[:event_key])
    # 日付を古い順に取得
    @days = @event.days.order(:date)
    # performers に対して name_tag をプリロード
    @performers = @event.performers.includes(:performer_name_tag)
    # stages に対して name_tag をプリロード
    @stages = @event.stages.includes(:stage_name_tag)

    # クエリパラメータから日付を決定
    @selected_date = params[:d].present? ? Date.parse(params[:d]) : @days.first.date

    # 対象日の performances のみに対して performer → name_tag / stage → name_tag まで全プリロード、かつ開始時間順でソート済み
    @performances = @event.performances
                          .joins(:day)
                          .where(days: { date: @selected_date })
                          .includes(
                            performer: :performer_name_tag, # performer.name_tag の N+1 対策
                            stage: :stage_name_tag           # stage.name_tag の N+1 対策
                          )
                          .order(:start_time)
                          .map do |p|
                            duration = p.duration
                            start_t = p.start_time
                            p.define_singleton_method(:start_h) { start_t.hour } # 時を事前に処理
                            p.define_singleton_method(:start_m) { start_t.min } # 分を事前に処理
                            p.define_singleton_method(:start_key) { start_t.hour * 60 + start_t.min } # 開始時間を文字列に変換
                            p.define_singleton_method(:formatted_start_time) { format("%02d:%02d", start_t.hour, start_t.min) } # hh:mm形式の開始時間を取得
                            p.define_singleton_method(:duration_in_5_min_units) { duration / 5 } # 出演時間を5分刻みに変換して取得
                            p.define_singleton_method(:show_start_time?) { duration >= 30 } # 出演時間が30分未満の場合は時刻を非表示にする
                            # line-clampクラスを事前計算して保持
                            line_clamp_class =
                              if duration <= 5
                                "line-clamp-1"
                              elsif duration <= 10
                                "line-clamp-2"
                              elsif duration <= 15
                                "line-clamp-3"
                              elsif duration <= 20
                                "line-clamp-4"
                              elsif duration <= 25
                                "line-clamp-5"
                              else
                                "line-clamp-6"
                              end
                            # メソッドとして持たせる
                            p.define_singleton_method(:line_clamp_class) { line_clamp_class }
                            p
                          end

    # ステージと出演情報を事前にグループ化しておく（@performances_by_stage[stage.id]で取得可能）
    @performances_by_stage = @performances.group_by(&:stage_id)


    # 開始時刻が最も早い出演者の出演時刻を取得
    earliest_time = @performances.map(&:start_time).min.hour
    # 終了時刻が最も遅い出演者の出演時刻を取得
    latest_end_time = @performances.map(&:end_time).max.hour
    # 時刻列用の配列を事前に作成する
    @time_slots = (earliest_time..latest_end_time).flat_map do |hour|
      (0..55).step(5).map { |minute| [ hour, minute ] }
    end

    # ヘッダー非表示フラグ
    @hidden_header = true
    # マージン不要フラグ
    @no_margin = true
    # イベント用ヘッダー表示フラグ
    @show_event_header = true
  end
end
