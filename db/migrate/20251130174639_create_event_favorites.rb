class CreateEventFavorites < ActiveRecord::Migration[8.1]
  def change
    create_table :event_favorites do |t|
      t.references :user, null: false, foreign_key: true
      t.references :event, null: false, foreign_key: true

      t.timestamps
    end
    # ユーザーとイベントの組み合わせが重複しないようにする
    add_index :event_favorites, [ :user_id, :event_id ], unique: true
  end
end
