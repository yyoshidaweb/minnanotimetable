class EventNameTag < ApplicationRecord
  # 1つのタグは複数イベントを持つ
  has_many :events, dependent: :destroy
end
