class CreateEvents < ActiveRecord::Migration[8.1]
  def change
    create_table :events do |t|
      t.string :event_key, null: false, limit: 50
      t.references :user, null: false, foreign_key: true
      t.references :event_name_tag, null: false, foreign_key: true
      t.boolean :is_published, null: false, default: false
      t.text :description

      t.timestamps
    end
    add_index :events, :event_key, unique: true
  end
end
