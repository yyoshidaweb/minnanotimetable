class EventsController < ApplicationController
  # ログイン必須（show以外）
  before_action :authenticate_user!, only: [ :new, :create, :update ]

  # イベント作成ページ表示
  def new
    @event = Event.new
    # nested form 用に空のタグオブジェクトを用意
    @event.build_event_name_tag
    @page_title = "イベント作成"
  end

  # イベント作成処理
  def create
    # Event 本体のパラメータ（description 等）を受け取る
    @event = current_user.events.build(event_params)

    # フォームで受け取るタグ名（fields_for で post される形）
    tag_name = params.dig(:event, :event_name_tag_attributes, :name)&.strip

    # タグ名が空ならエラーにする
    if tag_name.blank?
      # nested object を用意してエラーメッセージをビューで表示させる
      @event.build_event_name_tag(name: tag_name)
      # 子モデルにエラーを付ける
      @event.event_name_tag.errors.add(:name, :blank)
      # 親にエラーを伝える（Deviseエラー表示コンポーネントで表示するため）
      @event.errors.add(:base, @event.event_name_tag.errors.full_messages.first)
      return render :new, status: :unprocessable_entity
    end

    # 既存のタグがあれば使い、なければ作成（ユニーク制約はunique index により DB レベルで防ぐ）
    event_name_tag = EventNameTag.find_or_create_by!(name: tag_name)

    # Event に紐付け
    @event.event_name_tag = event_name_tag

    # event_key を生成
    @event.event_key = SecureRandom.urlsafe_base64(8)

    if @event.save
      redirect_to edit_timetable_url(@event.event_key), notice: "イベントを作成しました"
    else
      # 保存に失敗したら new を再表示（validation メッセージを @event に持たせる）
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    # 編集対象のイベントを取得
    @event = current_user.events.find_by!(event_key: params[:event_key])
    @page_title = "イベント情報編集"
  end

  def update
    # 編集対象の Event を取得（作成者が現在のユーザーであることを確認）
    @event = current_user.events.find_by!(event_key: params[:event_key])

    # フォームで受け取るタグ名（nested attributes の id は無視）
    tag_name = params.dig(:event, :event_name_tag_attributes, :name)&.strip

    # タグ名が空ならエラーにする
    if tag_name.blank?
      @event.build_event_name_tag(name: tag_name) unless @event.event_name_tag
      @event.event_name_tag.errors.add(:name, :blank)
      @event.errors.add(:base, @event.event_name_tag.errors.full_messages.first)
      return render :edit, status: :unprocessable_entity
    end

    # 既存のタグは更新せず、新しいタグに置き換える
    @event.event_name_tag = EventNameTag.find_or_create_by!(name: tag_name)

    # Event 本体を更新（description など）
    if @event.update(event_params.except(:event_name_tag_attributes))
      redirect_to edit_timetable_url(@event.event_key), notice: "イベントを更新しました"
    else
      render :edit, status: :unprocessable_entity
    end
  end

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

  private

  # 許可するパラメーター
  def event_params
    params.require(:event).permit(
      :description,
      event_name_tag_attributes: [ :name ] # event_name_tagに対するエラーの伝播を許可
    )
  end
end
