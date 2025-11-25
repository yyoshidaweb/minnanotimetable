class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  # Deviseで利用する機能を指定（DB認証、登録、パスワードリセット、セッション保持、メール検証、外部認証）
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable,
         :omniauthable, omniauth_providers: [ :google_oauth2 ]

  # バリデーション設定
  validates :name, presence: true, length: { maximum: 50 }
  validates :email, presence: true, uniqueness: true, length: { maximum: 255 }

  # Googleログイン時に呼ばれるユーザー検索 or 生成メソッド
  def self.from_omniauth(auth)
    # providerとuidの一致するユーザーを検索し、存在しない場合は新規作成
    where(provider: auth.provider, uid: auth.uid).first_or_create do |user|
      user.email = auth.info.email # Googleから取得したメールアドレスを設定
      user.password = Devise.friendly_token[0, 20] # ランダムなパスワードを自動生成
      user.name = auth.info.name if auth.info.respond_to?(:name) # 名前があれば設定
    end
  end
end
