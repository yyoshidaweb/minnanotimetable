class AddAiTimetableFieldsToUsers < ActiveRecord::Migration[8.1]
  def change
    # 今月使用回数
    add_column :users, :ai_timetable_count, :integer, null: false, default: 0
    # 最終リセット日
    add_column :users, :ai_timetable_reset_at, :date
  end
end
