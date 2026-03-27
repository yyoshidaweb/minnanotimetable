class PerformerNameTag < ApplicationRecord
  has_many :performers, dependent: :destroy

  # バリデーション
  validates :name, presence: true, uniqueness: true, length: { maximum: 100 }

  # 紐づくステージ数が3件以上のタグだけ取得するスコープ
  scope :popular, -> { joins(:performers).group("performer_name_tags.id").having("COUNT(performers.id) >= 3") }
end
