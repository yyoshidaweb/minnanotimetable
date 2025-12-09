class Day < ApplicationRecord
  belongs_to :event

  has_many :performances, dependent: :destroy

  # イベント内の開催日はユニーク
  validates :date, presence: true, uniqueness: { scope: :event_id }
end
