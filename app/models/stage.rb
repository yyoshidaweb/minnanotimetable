class Stage < ApplicationRecord
  belongs_to :event
  belongs_to :stage_name_tag

  # ステージをpositionの昇順で取得するためのデフォルトスコープ
  default_scope { order(:position) }

  has_many :performances, dependent: :destroy

  # nested attributes を許可（フォームで fields_for を使うため）
  accepts_nested_attributes_for :stage_name_tag, update_only: false

  validates :stage_name_tag, presence: true
  # stage_name_tag のバリデーションエラーを stage.errors に自動で伝播させる
  validates_associated :stage_name_tag

  # イベント内のステージはユニーク
  validates :stage_name_tag, presence: true, uniqueness: { scope: :event_id }
end
