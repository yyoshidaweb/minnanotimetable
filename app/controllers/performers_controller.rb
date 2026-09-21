class PerformersController < ApplicationController
  # イベントをセット
  before_action :set_event
  # indexとshow以外のアクションは所有者本人のみアクセス可能
  before_action :authorize_event!, except: %i[index show]
  # 非公開イベントの閲覧制御（公開ページ）
  before_action :authorize_published_event_access!, only: %i[ index show ]
  before_action :set_performer, only: %i[ show edit update destroy ]
  before_action :set_performances, only: %i[ show ]
  before_action :set_page_title, except: %i[ destroy ]
  before_action :show_event_header, except: %i[ destroy ]
  # モーダル表示時はレイアウトの空turbo-frame#modalと重ならないようにする
  layout -> { (modal_turbo_frame? && %w[show edit].include?(action_name)) ? false : "application" }

  def index
    @performers = @event.performers
                        .order_by_name
                        .includes(:performer_name_tag)
                        .preload(performances: [ :day, { stage: :stage_name_tag } ])
    # 所有者のみ「未設定項目あり」で絞り込み可能
    if event_owner? && params[:filter] == "unset"
      @performers = @performers.with_unset_items
    end
    # お気に入り登録している出演者IDの配列を取得
    if user_signed_in?
      @favorite_performer_map = current_user.favorite_performer_map
    end
  end

  def show
    # お気に入り登録している出演情報IDの配列を取得
    if user_signed_in?
      @favorite_performance_map =
        current_user.favorite_performance_map_by_performer(@performer)
    end
  end

  def new
    @performer = @event.performers.build
    @performer.build_performer_name_tag
  end

  def create
    @performers = @event.performers.includes(:performer_name_tag)
    @performer = @event.performers.build(performer_params)

    # フォームで受け取るタグ名（fields_for で post される形）
    tag_name = params.dig(:performer, :performer_name_tag_attributes, :name)&.strip

    # タグ名が空ならエラーにする
    if tag_name.blank?
      # nested object を用意してエラーメッセージをビューで表示させる
      @performer.build_performer_name_tag(name: tag_name)
      # 子モデルにエラーを付ける
      @performer.performer_name_tag.errors.add(:name, :blank)
      # 親にエラーを伝える（Deviseエラー表示コンポーネントで表示するため）
      @performer.errors.add(:base, @performer.performer_name_tag.errors.full_messages.first)
      return render :new, status: :unprocessable_entity
    end
    # 既存のタグがあれば使い、なければ作成（ユニーク制約はunique index により DB レベルで防ぐ）
    performer_name_tag = PerformerNameTag.find_or_initialize_by(name: tag_name)

    # タグのバリデーションチェック
    unless performer_name_tag.save
      @performer.build_performer_name_tag(name: tag_name)
      @performer.performer_name_tag.errors.copy!(performer_name_tag.errors) # 子モデルのエラーをコピー
      @performer.errors.add(:base, performer_name_tag.errors.full_messages.first)
      return render :new, status: :unprocessable_entity
    end

    # Performer に紐付け
    @performer.performer_name_tag = performer_name_tag

    if @performer.save
      respond_to do |format|
        format.turbo_stream
        format.html { redirect_to event_performers_path(@event.event_key), notice: "出演者を作成しました。" }
      end
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  # 出演者更新。
  # from_modal 送信時は成功後 modal_return_url へ、失敗時は turbo-stream で #modal を差し替える。
  def update
    # フォームのタグ名を取得
    tag_name = params.dig(:performer, :performer_name_tag_attributes, :name)&.strip

    # タグ名が空欄ならエラー
    if tag_name.blank?
      # 既存の nested attributes 用オブジェクトを差し込む
      @performer.build_performer_name_tag(name: tag_name) unless @performer.performer_name_tag
      # 子モデルにエラーを付ける
      @performer.performer_name_tag.errors.add(:name, :blank)
      # 親にエラーを伝える
      @performer.errors.add(:base, @performer.performer_name_tag.errors.full_messages.first)
      return render_edit_unprocessable("performers/modal_edit")
    end

    # 既存タグを探す or 新規作成
    performer_name_tag = PerformerNameTag.find_or_initialize_by(name: tag_name)

    # タグのバリデーションチェック
    unless performer_name_tag.valid?
      # 入力値をフォームに残す
      @performer.performer_name_tag = performer_name_tag
      @performer.performer_name_tag.errors.copy!(performer_name_tag.errors)
      @performer.errors.add(:base, performer_name_tag.errors.full_messages.first)
      return render_edit_unprocessable("performers/modal_edit")
    end

    performer_name_tag.save if performer_name_tag.new_record?

    # Performer に新しいタグを紐付け
    @performer.performer_name_tag = performer_name_tag

    # Performer本体を更新（ネストされたフィールドを除く）
    if @performer.update(performer_params.except(:performer_name_tag_attributes))
      if modal_form_submission?
        redirect_to modal_return_url, notice: "出演者を更新しました。", status: :see_other
      else
        redirect_to event_performer_path(@event.event_key, @performer), notice: "出演者を更新しました。"
      end
    else
      render_edit_unprocessable("performers/modal_edit")
    end
  end

  # 出演者削除。
  # from_modal 送信時は modal_return_url へ、通常時は出演者一覧へ戻る。
  def destroy
    @performer.destroy!
    if modal_form_submission?
      redirect_to modal_return_url, notice: "出演者を削除しました。", status: :see_other
    else
      redirect_to event_performers_path(@event.event_key), notice: "出演者を削除しました。", status: :see_other
    end
  end

  private
    # イベントを取得
    def set_event
      @event = Event.find_by!(event_key: params[:event_event_key])
    end

    # イベントの所有者かどうか
    def event_owner?
      user_signed_in? && @event.user == current_user
    end
    helper_method :event_owner?

    # イベントの所有者かどうかチェック（異なる場合は404エラーを発生させる）
    def authorize_event!
      raise ActiveRecord::RecordNotFound unless event_owner?
    end

    # 非公開イベントは作成者のみ閲覧可能
    def authorize_published_event_access!
      authorize_published_event!(@event)
    end

    # 出演者を取得
    def set_performer
      @performer = @event.performers.find(params[:id])
    end

    # 出演情報を取得
    def set_performances
      @performances = @performer.performances.ordered_for_performer_detail
    end

    # ページタイトルと戻り先を設定（一覧タブには戻るボタンを付けない）
    def set_page_title
      case action_name
      when "index"
        @page_title = "出演者一覧"
      when "new", "create"
        @page_title = "出演者を作成"
        @back_path = event_performers_path(@event.event_key)
        @back_label = "一覧"
      when "show"
        @page_title = "出演者詳細"
        @back_path = event_performers_path(@event.event_key)
        @back_label = "一覧"
      when "edit", "update"
        @page_title = "出演者を編集"
        @back_path = event_performer_path(@event.event_key, @performer)
        @back_label = "詳細"
      end
    end

    # イベントヘッダー表示フラグ
    def show_event_header
      # イベント用ヘッダー表示フラグ
      @show_event_header = true
    end

    # 許可するパラメーター
    def performer_params
      params.require(:performer).permit(
        :description,
        :website_url,
        performer_name_tag_attributes: [ :name ] # performer_name_tagに対するエラーの伝播を許可
      )
    end
end
