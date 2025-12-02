class Stage < ApplicationRecord
  belongs_to :event
  belongs_to :stage_name_tag

  # ステージをpositionの昇順で取得するためのデフォルトスコープ
  default_scope { order(:position) }

  has_many :performances, dependent: :destroy
end
