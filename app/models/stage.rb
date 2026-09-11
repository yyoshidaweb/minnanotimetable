class Stage < ApplicationRecord
  before_create :set_position_to_last
  # マイグレーション直後にスキーマキャッシュが古いと、SELECT * では
  # admission_restricted を読めても UPDATE 対象から除外されるため再読込する
  before_save :ensure_admission_restricted_column_known

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

  private

    # 新規作成時に position を最後尾に設定
    def set_position_to_last
      self.position =
        event.stages.maximum(:position).to_i + 1
    end

    # admission_restricted が column_names に無いときはスキーマを再読込する
    def ensure_admission_restricted_column_known
      return if self.class.column_names.include?("admission_restricted")

      self.class.reset_column_information
    end
end
