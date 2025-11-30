class Day < ApplicationRecord
  belongs_to :event

  has_many :performances, dependent: :destroy
end
