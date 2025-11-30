class Stage < ApplicationRecord
  belongs_to :event
  belongs_to :stage_name_tag

  has_many :performances, dependent: :destroy
end
