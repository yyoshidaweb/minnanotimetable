class PerformerFavorite < ApplicationRecord
  belongs_to :performer
  belongs_to :user
  # ユーザーと出演者の組み合わせが重複しないようにする
  validates :performance_id, uniqueness: { scope: :user_id }
end
