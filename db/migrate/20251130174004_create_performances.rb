class CreatePerformances < ActiveRecord::Migration[8.1]
  def change
    create_table :performances do |t|
      t.references :performer, null: false, foreign_key: true
      t.references :stage, foreign_key: true
      t.references :day, foreign_key: true
      t.time :start_time
      t.time :end_time
      t.integer :duration # start/end が揃ったら、（end_time - start_time） で出演時間を自動計算して保存する

      t.timestamps
    end
  end
end
