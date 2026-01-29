class CreateEvents < ActiveRecord::Migration[8.1]
  def change
    create_table :events do |t|
      t.string :event_key, null: false, limit: 50
      t.references :user, null: false, foreign_key: true
      t.references :event_name_tag, null: false, foreign_key: true
      t.boolean :is_published, null: false, default: true
      t.text :description

      t.timestamps
    end
    add_index :events, :event_key, unique: true
    add_index :events, [ :user_id, :event_name_tag_id ], unique: true
  end
end
