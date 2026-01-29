class Event < ApplicationRecord
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

  # ===== バリデーション =====
  validates :event_key, presence: true, uniqueness: true
  validates :event_name_tag, presence: true
  validates_associated :event_name_tag # event_name_tag のバリデーションエラーを event.errors に自動で伝播させる

  # 1ユーザー内のイベント名はユニーク
  validates :event_name_tag, presence: true, uniqueness: { scope: :user_id }

  # トップページ用に新しい順で最大3件取得するスコープ
  scope :recent_for_home, -> { order(created_at: :desc).limit(3) }

  # フォームや一覧表示用の名前
  def display_name
    event_name_tag.name
  end
end
