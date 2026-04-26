class User < ApplicationRecord
  # ユーザーが作成したイベント
  has_many :events, dependent: :destroy

  # お気に入りのイベント
  has_many :event_favorites, dependent: :destroy
  has_many :favorite_events, through: :event_favorites, source: :event
  # お気に入りの出演情報
  has_many :performance_favorites, dependent: :destroy
  has_many :favorite_performances, through: :performance_favorites, source: :performance

  # ユーザーロールの定義
  enum :role, {
    free: 0, # 無料ユーザー
    developer: 1 # 開発者
  }

  # 予約語として使用禁止の username リスト
  MANUAL_RESERVED_USERNAMES = %w[
    sign_in
    sign_out
    sign_up
    auth
    password
    new
    edit
    cancel
    admin
    login
    logout
    settings
  ].freeze

  # ユーザー名を生成するメソッドを呼び出す
  before_validation :generate_username, on: :create

  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  # Deviseで利用する機能を指定（DB認証、登録、パスワードリセット、セッション保持、メール検証、外部認証）
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable,
         :omniauthable, omniauth_providers: [ :google_oauth2 ]

  # バリデーション設定
  validates :name, presence: true, length: { maximum: 50 }
  validates :email, presence: true, uniqueness: true, length: { maximum: 255 }
  validates :username, presence: true, uniqueness: true, length: { maximum: 20 }
  validates :description, length: { maximum: 500 }
  # username が予約語でないことを確認するカスタムバリデーション
  validate :username_must_not_be_reserved

  # Googleログイン時に呼ばれるユーザー検索 or 生成メソッド
  def self.from_omniauth(auth)
    # providerとuidの一致するユーザーを検索し、存在しない場合は新規作成
    where(provider: auth.provider, uid: auth.uid).first_or_create do |user|
      user.email = auth.info.email # Googleから取得したメールアドレスを設定
      user.name = auth.info.name if auth.info.respond_to?(:name) # 名前があれば設定
    end
  end

  # Google アカウントの場合はパスワード不要
  def password_required?
    provider.blank? && super
  end

  # お気に入りタイムテーブル（event）idを取得する
  def favorite_event_id(event)
    event_favorites.find_by(event_id: event.id)&.id
  end

  # performerに紐づくお気に入りを Hash で取得
  def favorite_performance_map_by_performer(performer)
    performance_favorites
      .joins(:performance) # performanceテーブル結合
      .where(performances: { performer_id: performer.id })
      .pluck(:performance_id, :id) # [performance_id, favorite_id]
      .to_h # Hash化
  end

  # performancesの配列に紐づくお気に入りを Hash で取得
  def favorite_performance_map_by_performances(performances)
    performance_favorites
      .where(performance_id: performances)
      .pluck(:performance_id, :id)
      .to_h
  end

  # performerごとに「お気に入りperformanceが存在するか」を取得
  def favorite_performer_map
    performance_favorites
      .joins(:performance) # performancesと結合
      .pluck("performances.performer_id", :performance_id)
      .each_with_object({}) do |(performer_id, _), map|
        map[performer_id] = true # performerに1件でもあればtrue
      end
  end

  # AIタイムテーブル機能の上限回数を取得
  def ai_timetable_monthly_limit
    case role.to_sym
    # 無料ユーザー
    when :free
      10
    # 開発者
    when :developer
      300
    end
  end

  # AIタイムテーブル機能の利用可能か判定
  def ai_timetable_available?
    reset_if_needed
    ai_timetable_count < ai_timetable_monthly_limit
  end

  # カウント増加
  def increment_ai_timetable_count!
    reset_if_needed
    increment!(:ai_timetable_count)
  end

  # AIタイムテーブル機能の残り利用回数を取得
  def remaining_ai_timetable_count
    reset_if_needed
    limit = ai_timetable_monthly_limit
    [ limit - ai_timetable_count, 0 ].max # マイナス防止
  end

  private

  # ユーザー名を生成するメソッド
  def generate_username
    return if username.present? # 既に設定されていれば生成しない
    loop do
      # 8バイト（11文字程度）のランダムなURLセーフ文字列を生成
      random_id = SecureRandom.urlsafe_base64(8)
      # 作成したIDが既に存在しないか場合は保存
      break self.username = random_id unless User.exists?(username: random_id)
    end
  end

  # username が予約語でないことを確認するカスタムバリデーション
  def username_must_not_be_reserved
    if MANUAL_RESERVED_USERNAMES.include?(username)
      errors.add(:username, "は使用できません。別のIDを登録してください。")
    end
  end

  # 月が変わったらAIタイムテーブル機能のカウントをリセット
  def reset_if_needed
    return if ai_timetable_reset_at&.month == Date.current.month &&
              ai_timetable_reset_at&.year == Date.current.year
    update!(
      ai_timetable_count: 0,
      ai_timetable_reset_at: Date.current
    )
  end
end
