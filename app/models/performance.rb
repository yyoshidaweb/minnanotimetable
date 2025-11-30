class Performance < ApplicationRecord
  belongs_to :day
  belongs_to :performer
  belongs_to :stage
end
