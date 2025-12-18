class Day < ApplicationRecord
  belongs_to :event

  # 出演情報がある場合も削除可能
  has_many :performances, dependent: :nullify

  # イベント内の開催日はユニーク
  validates :date, presence: true, uniqueness: { scope: :event_id }
end
