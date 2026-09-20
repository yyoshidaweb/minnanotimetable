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

  # タイムテーブル描画可能な出演情報を1件以上持つイベント
  scope :with_timetable_ready_performances, -> {
    where(id: Performance.timetable_ready.joins(:performer).select("performers.event_id"))
  }

  # みんなが作ったタイムテーブルのうち、未来イベントを取得
  # タイムテーブル描画可能な出演情報が1件以上ある公開イベントが対象
  scope :future_all, -> {
    now = Time.current.to_date
    visibility_public
      .with_timetable_ready_performances
      .left_joins(:event_favorites)
      .left_joins(performers: :performances)
      .left_joins(:days)
      .includes(:user, :days, :event_name_tag, :event_favorites)
      .group(:id)
      .having("MAX(days.date) >= ?", now)
      .order(
        # 直近の開催日（未来日のうち最も早い日）で並べる
        Arel.sql(sanitize_sql_array([ "MIN(CASE WHEN days.date >= ? THEN days.date END) ASC", now ])),
        Arel.sql("COUNT(DISTINCT event_favorites.id) DESC"), # お気に入り数の多い順
        Arel.sql("COUNT(DISTINCT performances.id) DESC"), # 出演情報の多い順
        created_at: :desc, # 作成日の降順
        id: :asc # ページング用の安定した全順序
      )
  }

  # みんなが作ったタイムテーブルのうち、過去イベントを取得
  # タイムテーブル描画可能な出演情報が1件以上ある公開イベントが対象
  scope :past_all, -> {
    now = Time.current.to_date
    visibility_public
      .with_timetable_ready_performances
      .left_joins(:event_favorites)
      .left_joins(performers: :performances)
      .left_joins(:days)
      .includes(:user, :days, :event_name_tag, :event_favorites)
      .group(:id)
      .having("MAX(days.date) < ?", now)
      .order(
        Arel.sql("MAX(days.date) DESC"), # 現在日付に近い順（HAVINGで過去のみに絞済み）
        Arel.sql("COUNT(DISTINCT event_favorites.id) DESC"), # お気に入り数の多い順
        Arel.sql("COUNT(DISTINCT performances.id) DESC"), # 出演情報の多い順
        created_at: :desc, # 作成日の降順
        id: :asc # ページング用の安定した全順序
      )
  }

  # タイムテーブル描画可能な出演情報が0件の公開イベント（開催日未定を含む）
  # 並び: 開催日あり（現在日付に近い順）→ 開催日未定
  scope :without_timetable_ready_all, -> {
    now = Time.current.to_date
    visibility_public
      .where.not(id: Performance.timetable_ready.joins(:performer).select("performers.event_id"))
      .left_joins(:event_favorites)
      .left_joins(performers: :performances)
      .left_joins(:days)
      .includes(:user, :days, :event_name_tag, :event_favorites)
      .group(:id)
      .order(
        Arel.sql("CASE WHEN MAX(days.date) IS NULL THEN 1 ELSE 0 END ASC"), # 開催日ありを先に
        Arel.sql(Event.send(:days_proximity_order_sql, now)), # 現在日付に近い順
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

  # みんなが作ったタイムテーブル（未来→過去→出演情報なし）をページングする
  # @return [Hash] :events, :page, :next_page, :show_upcoming_heading, :past_index,
  #   :without_timetable_ready_index
  def self.paginate_public_all(page:)
    page = normalize_page(page)
    offset = (page - 1) * PER_PAGE
    segments = [
      [ :future, future_all ],
      [ :past, past_all ],
      [ :without_timetable_ready, without_timetable_ready_all ]
    ].map { |key, scope| [ key, scope, grouped_event_count(scope) ] }

    total = segments.sum { |_, _, count| count }
    events = []
    past_index = nil
    without_timetable_ready_index = nil
    skip = offset
    slots = PER_PAGE

    segments.each do |key, scope, count|
      break if slots.zero?
      if skip >= count
        skip -= count
        next
      end

      section_offset = skip
      skip = 0
      take = [ slots, count - section_offset ].min
      batch = scope.offset(section_offset).limit(take).to_a

      # このページで当該セクションが始まるときだけ見出し位置を渡す
      if section_offset.zero? && batch.any?
        past_index = events.size if key == :past
        without_timetable_ready_index = events.size if key == :without_timetable_ready
      end

      events.concat(batch)
      slots -= batch.size
    end

    {
      events: events,
      page: page,
      next_page: (offset + events.size) < total ? page + 1 : nil,
      show_upcoming_heading: page == 1 && segments.dig(0, 2).to_i.positive?,
      past_index: past_index,
      without_timetable_ready_index: without_timetable_ready_index
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

    # group(:id) 付きスコープの件数を返す（Hash展開を避けてスカラー件数にする）
    def grouped_event_count(scope)
      grouped_scope = scope.unscope(:includes, :order).select(:id)
      unscoped.from(grouped_scope, :events).count
    end

    # 開催日と基準日の差の最小値（SQLite / PostgreSQL両対応）
    def days_proximity_order_sql(date)
      if connection.adapter_name.match?(/PostgreSQL/i)
        sanitize_sql_array([ "MIN(ABS(days.date - ?))", date ])
      else
        sanitize_sql_array([ "MIN(ABS(JULIANDAY(days.date) - JULIANDAY(?)))", date ])
      end
    end
  end
end
