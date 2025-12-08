class EventNameTag < ApplicationRecord
  # 1つのタグは複数イベントを持つ
  has_many :events, dependent: :restrict_with_error

  # バリデーション
  validates :name, presence: true, uniqueness: true

  # 紐づくイベント数が3件以上のタグだけ取得するスコープ
  scope :popular, -> { joins(:events).group("event_name_tags.id").having("COUNT(events.id) >= 3") }
end
