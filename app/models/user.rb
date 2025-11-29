class User < ApplicationRecord
  # 予約語として使用禁止の user_id リスト
  MANUAL_RESERVED_USER_IDS = %w[
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

  # ユーザーIDを生成するメソッドを呼び出す
  before_validation :generate_user_id, on: :create

  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  # Deviseで利用する機能を指定（DB認証、登録、パスワードリセット、セッション保持、メール検証、外部認証）
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable,
         :omniauthable, omniauth_providers: [ :google_oauth2 ]

  # バリデーション設定
  validates :name, presence: true, length: { maximum: 50 }
  validates :email, presence: true, uniqueness: true, length: { maximum: 255 }
  validates :user_id, presence: true, uniqueness: true, length: { maximum: 20 }
  validates :description, length: { maximum: 500 }
  # user_id が予約語でないことを確認するカスタムバリデーション
  validate :user_id_must_not_be_reserved

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

  private

  # ユーザーIDを生成するメソッド
  def generate_user_id
    return if user_id.present? # 既に設定されていれば生成しない
    loop do
      # 8バイト（11文字程度）のランダムなURLセーフ文字列を生成
      random_id = SecureRandom.urlsafe_base64(8)
      # 作成したIDが既に存在しないか場合は保存
      break self.user_id = random_id unless User.exists?(user_id: random_id)
    end
  end

  # user_id が予約語でないことを確認するカスタムバリデーション
  def user_id_must_not_be_reserved
    if MANUAL_RESERVED_USER_IDS.include?(user_id)
      errors.add(:user_id, "は使用できません。別のIDを登録してください。")
    end
  end
end
