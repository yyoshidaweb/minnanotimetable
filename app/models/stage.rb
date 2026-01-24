class Stage < ApplicationRecord
  belongs_to :event
  belongs_to :stage_name_tag

  # 出演情報がある場合も削除可能
  has_many :performances, dependent: :nullify

  # nested attributes を許可（フォームで fields_for を使うため）
  accepts_nested_attributes_for :stage_name_tag, update_only: false

  validates :stage_name_tag, presence: true
  # stage_name_tag のバリデーションエラーを stage.errors に自動で伝播させる
  validates_associated :stage_name_tag

  # イベント内のステージはユニーク
  validates :stage_name_tag, presence: true, uniqueness: { scope: :event_id }

  validates :address, length: { maximum: 50 }

  # フォームや一覧表示用の名前
  def display_name
    stage_name_tag.name
  end
end
