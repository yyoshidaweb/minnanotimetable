class CreateStages < ActiveRecord::Migration[8.1]
  def change
    create_table :stages do |t|
      t.references :event, null: false, foreign_key: true
      t.references :stage_name_tag, null: false, foreign_key: true
      t.text :description
      t.string :address, limit: 50

      # ステージの表示順を管理するためのカラム
      t.integer :position, null: false, default: 0

      t.timestamps
    end
  end
end
