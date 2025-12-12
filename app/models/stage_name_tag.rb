class StageNameTag < ApplicationRecord
  # 1つのタグは複数ステージを持つ
  has_many :stages, dependent: :restrict_with_error

  # バリデーション
  validates :name, presence: true, uniqueness: true

  # 紐づくステージ数が3件以上のタグだけ取得するスコープ
  scope :popular, -> { joins(:stages).group("stage_name_tags.id").having("COUNT(stages.id) >= 3") }
end
