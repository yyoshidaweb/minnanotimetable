class EventNameTag < ApplicationRecord
  # 1つのタグは複数イベントを持つ
  has_many :events, dependent: :restrict_with_error

  # バリデーション
  validates :name, presence: true, uniqueness: true
end
