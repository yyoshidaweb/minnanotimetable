class CreateStageNameTags < ActiveRecord::Migration[8.1]
  def change
    create_table :stage_name_tags do |t|
      t.string :name, null: false, limit: 50

      t.timestamps
    end
    add_index :stage_name_tags, :name, unique: true
  end
end
