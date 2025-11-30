class PerformerFavorite < ApplicationRecord
  belongs_to :performer
  belongs_to :user
end
