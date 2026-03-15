module MyTimetablesHelper
  # 本人のタイムテーブルかどうかを判定
  def my_timetable_owner?
    @user == current_user
  end
end
