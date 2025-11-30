class PerformerNameTag < ApplicationRecord
  has_many :performers, dependent: :destroy
end
