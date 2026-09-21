class Performer < ApplicationRecord
  belongs_to :event
  belongs_to :performer_name_tag

  # 出演者を削除すると、紐づいている出演情報も全て削除される
  has_many :performances, -> { merge(Performance.ordered_by_festival_day_and_time) },
           dependent: :destroy

  # nested attributes を許可（フォームで fields_for を使うため）
  accepts_nested_attributes_for :performer_name_tag, update_only: false

  validates :performer_name_tag, presence: true
  # performer_name_tag のバリデーションエラーを performer.errors に自動で伝播させる
  validates_associated :performer_name_tag

  # イベント内の出演者はユニーク
  validates :performer_name_tag, presence: true, uniqueness: { scope: :event_id }

  validates :website_url,
            length: { maximum: 50 },
            format: { with: URI::DEFAULT_PARSER.make_regexp(%w[http https]),
                      message: "は有効なURL形式で入力してください" },
            allow_blank: true

  # 出演者名の昇順で取得するスコープ
  scope :order_by_name, -> {
    joins(:performer_name_tag)
      .order("performer_name_tags.name ASC")
  }

  # 未設定項目のある出演情報を持つ、または出演情報が1件もない出演者
  scope :with_unset_items, -> {
    where(
      id: left_outer_joins(:performances)
        .where(
          "performances.id IS NULL OR performances.day_id IS NULL OR " \
          "performances.stage_id IS NULL OR performances.start_time IS NULL OR " \
          "performances.duration IS NULL"
        )
        .select(:id)
    )
  }

  # フォームや一覧表示用の名前
  def display_name
    performer_name_tag.name
  end

  # 所有者向けバッジ用。出演情報がない場合は「出演情報」、ある場合は欠けている項目の和集合
  def unset_field_labels
    return [ "出演情報" ] if performances.empty?

    labels = performances.flat_map(&:missing_field_labels)
    %w[出演日 時刻 ステージ].select { |label| labels.include?(label) }
  end

  # 未設定項目ありフィルタの対象か
  def has_unset_items?
    performances.empty? || performances.any?(&:incomplete?)
  end
end
