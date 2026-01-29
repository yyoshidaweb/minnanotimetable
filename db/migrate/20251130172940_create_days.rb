class CreateDays < ActiveRecord::Migration[8.1]
  def change
    create_table :days do |t|
      t.references :event, null: false, foreign_key: true
      t.date :date, null: false

      t.timestamps
    end
    add_index :days, [ :event_id, :date ], unique: true
  end
end
