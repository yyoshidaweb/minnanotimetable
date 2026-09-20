class Event < ApplicationRecord
  # 一覧ページの1ページあたりの表示件数（無限スクロール）
  PER_PAGE = 20

  # イベントは一つのユーザーに属する
  belongs_to :user
  # イベントは一つのイベント名タグに属する
  belongs_to :event_name_tag

  # 関連
  has_many :days, dependent: :destroy
  has_many :stages, -> { order(:position) }, dependent: :destroy
  has_many :performers, dependent: :destroy
  # 多対多
  has_many :performances, through: :days
  has_many :event_favorites, dependent: :destroy

  # イベントをお気に入り登録しているユーザーの一覧を取得したいときに使うエイリアス
  has_many :favorited_users, through: :event_favorites, source: :user

  # nested attributes を許可（フォームで fields_for を使うため）
  accepts_nested_attributes_for :event_name_tag, update_only: false

  enum :visibility, {
    public: 0,
    unlisted: 1,
    private: 2
  }, prefix: true

  # ===== バリデーション =====
  validates :event_key, presence: true, uniqueness: true
  validates :event_name_tag, presence: true
  validates_associated :event_name_tag # event_name_tag のバリデーションエラーを event.errors に自動で伝播させる

  # 1ユーザー内のイベント名はユニーク
  validates :event_name_tag, presence: true, uniqueness: { scope: :user_id }

  # みんなが作ったタイムテーブルのうち、未来イベントを取得
  scope :future_all, -> {
    now = Time.current.to_date
    visibility_public
      .left_joins(:event_favorites)
      .left_joins(performers: :performances)
      .left_joins(:days)
      .includes(:user, :days, :event_name_tag, :event_favorites)
      .group(:id)
      .having("MAX(days.date) >= ?", now)
      .order(
        Arel.sql("CASE WHEN MAX(days.date) >= '#{now}' THEN MAX(days.date) END ASC"), # 現在日付に近い順
        Arel.sql("COUNT(DISTINCT event_favorites.id) DESC"), # お気に入り数の多い順
        Arel.sql("COUNT(DISTINCT performances.id) DESC"), # 出演情報の多い順
        created_at: :desc, # 作成日の降順
        id: :asc # ページング用の安定した全順序
      )
  }

  # みんなが作ったタイムテーブルのうち、過去イベントを取得
  scope :past_all, -> {
    now = Time.current.to_date
    visibility_public
      .left_joins(:event_favorites)
      .left_joins(performers: :performances)
      .left_joins(:days)
      .includes(:user, :days, :event_name_tag, :event_favorites)
      .group(:id)
      .having("MAX(days.date) < ?", now)
      .order(
        Arel.sql("CASE WHEN MAX(days.date) < '#{now}' THEN MAX(days.date) END DESC"), # 現在日付に近い順
        Arel.sql("COUNT(DISTINCT event_favorites.id) DESC"), # お気に入り数の多い順
        Arel.sql("COUNT(DISTINCT performances.id) DESC"), # 出演情報の多い順
        created_at: :desc, # 作成日の降順
        id: :asc # ページング用の安定した全順序
      )
  }

  # トップページ用にみんなが作ったタイムテーブルを取得
  scope :popular_for_home, -> {
    popular_for_all.limit(20)
  }

  # 作成したタイムテーブル
  scope :recent_created_by, ->(user) {
    where(user: user)
      .includes(:user, :days, :event_name_tag, :event_favorites)
      .order(created_at: :desc, id: :asc) # idはページング用の安定した全順序
  }

  # トップページ用に作成したタイムテーブルを取得
  scope :recent_created_for_home, ->(user) {
    recent_created_by(user).limit(3)
  }

  # お気に入りタイムテーブル（最後にお気に入りした順）
  # 非公開イベントは作成者本人のお気に入り一覧にのみ表示する
  scope :recent_favorite_by, ->(user) {
    joins(:event_favorites)
      .where(event_favorites: { user_id: user.id })
      .where("events.visibility != ? OR events.user_id = ?", visibilities[:private], user.id)
      .includes(:user, :days, :event_name_tag, :event_favorites)
      .order("event_favorites.created_at DESC, events.id ASC") # idはページング用の安定した全順序
  }

  # トップページ用にお気に入りタイムテーブルを取得
  scope :recent_favorite_for_home, ->(user) {
    recent_favorite_by(user).limit(3)
  }

  # リレーションをページングする（作成・お気に入り一覧向け）
  # @return [Hash] :events, :page, :next_page
  def self.paginate_relation(relation, page:)
    page = normalize_page(page)
    offset = (page - 1) * PER_PAGE
    events = relation.offset(offset).limit(PER_PAGE).to_a
    # 満額取得できたときだけ次ページの有無を確認する（includesなしで余分なeager loadを避ける）
    has_more = events.size == PER_PAGE &&
      relation.unscope(:includes).offset(offset + PER_PAGE).limit(1).exists?

    { events: events, page: page, next_page: has_more ? page + 1 : nil }
  end

  # みんなが作ったタイムテーブル（未来→過去）をページングする
  # @return [Hash] :events, :page, :next_page, :show_upcoming_heading, :past_index
  def self.paginate_public_all(page:)
    page = normalize_page(page)
    offset = (page - 1) * PER_PAGE
    future_scope = future_all
    past_scope = past_all
    future_count = grouped_event_count(future_scope)
    past_count = grouped_event_count(past_scope)
    total = future_count + past_count

    events = []
    past_index = nil

    if offset < future_count
      future_limit = [ PER_PAGE, future_count - offset ].min
      futures = future_scope.offset(offset).limit(future_limit).to_a
      events.concat(futures)

      remaining = PER_PAGE - futures.size
      if remaining > 0 && past_count > 0
        pasts = past_scope.limit(remaining).to_a
        past_index = events.size if pasts.any?
        events.concat(pasts)
      elsif page == 1
        # 1ページ目で未来のみの場合も、従来どおりセクション見出し用に境界を渡す
        past_index = events.size
      end
    else
      past_offset = offset - future_count
      pasts = past_scope.offset(past_offset).limit(PER_PAGE).to_a
      events.concat(pasts)
      # このページの先頭が「最初の過去イベント」のときだけ見出しを出す
      past_index = 0 if past_offset.zero? && pasts.any?
    end

    {
      events: events,
      page: page,
      next_page: (offset + events.size) < total ? page + 1 : nil,
      show_upcoming_heading: page == 1 && future_count.positive?,
      past_index: past_index
    }
  end

  # フォームや一覧表示用の名前
  def display_name
    event_name_tag.name
  end

  # URLを知っていれば閲覧可能かどうか
  def viewable_by_url?
    !visibility_private?
  end

  # 検索エンジンへのインデックス対象かどうか
  def search_indexable?
    visibility_public?
  end

  class << self
    private

    def normalize_page(page)
      [ page.to_i, 1 ].max
    end

    # group(:id) 付きスコープの件数を返す
    def grouped_event_count(scope)
      scope.unscope(:includes, :order).count.size
    end
  end
end
