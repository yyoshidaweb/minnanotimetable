class Performer < ApplicationRecord
  belongs_to :event
  belongs_to :performer_name_tag

  # 出演者を削除すると、紐づいている出演情報も全て削除される
  has_many :performances, dependent: :destroy
  has_many :performer_favorites, dependent: :destroy

  # 出演者をお気に入り登録しているユーザーの一覧を取得したいときに使うエイリアス
  has_many :favorited_users, through: :performer_favorites, source: :user

  # nested attributes を許可（フォームで fields_for を使うため）
  accepts_nested_attributes_for :performer_name_tag, update_only: false

  validates :performer_name_tag, presence: true
  # performer_name_tag のバリデーションエラーを performer.errors に自動で伝播させる
  validates_associated :performer_name_tag

  # イベント内の出演者はユニーク
  validates :performer_name_tag, presence: true, uniqueness: { scope: :event_id }

  validates :website_url,
            length: { maximum: 50 },
            format: { with: URI::DEFAULT_PARSER.make_regexp(%w[http https]),
                      message: "は有効なURL形式で入力してください" },
            allow_blank: true

  # 出演者名の昇順で取得するスコープ
  scope :order_by_name, -> {
    joins(:performer_name_tag)
      .order("performer_name_tags.name ASC")
  }

  # フォームや一覧表示用の名前
  def display_name
    performer_name_tag.name
  end
end
