class StageNameTag < ApplicationRecord
  has_many :stages, dependent: :destroy
end
