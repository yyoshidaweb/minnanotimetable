class ChangeNameLimitTo100OnNameTags < ActiveRecord::Migration[8.1]
  def change
    change_column :event_name_tags, :name, :string, limit: 100, null: false
    change_column :performer_name_tags, :name, :string, limit: 100, null: false
    change_column :stage_name_tags, :name, :string, limit: 100, null: false
  end
end
