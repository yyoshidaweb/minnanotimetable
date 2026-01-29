class CreatePerformers < ActiveRecord::Migration[8.1]
  def change
    create_table :performers do |t|
      t.references :event, null: false, foreign_key: true
      t.references :performer_name_tag, null: false, foreign_key: true
      t.text :description
      t.string :website_url, limit: 50

      t.timestamps
    end
    add_index :performers, [ :event_id, :performer_name_tag_id ], unique: true
  end
end
