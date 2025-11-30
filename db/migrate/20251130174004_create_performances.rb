class CreatePerformances < ActiveRecord::Migration[8.1]
  def change
    create_table :performances do |t|
      t.references :performer, null: false, foreign_key: true
      t.references :stage, null: false, foreign_key: true
      t.references :day, null: false, foreign_key: true
      t.time :start_time, null: false
      t.time :end_time, null: false
      t.integer :duration, null: false # end_time - start_time で出演時間を自動計算して保存する

      t.timestamps
    end
  end
end
