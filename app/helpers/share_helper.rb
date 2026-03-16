module ShareHelper
  # 共有用のURLを返す
  def share_url_for
    case params[:type]
    when "event"
      show_timetable_url(@event.event_key)
    when "my-timetable"
      show_my_timetable_url(@event.event_key, @user.username)
    end
  end

  # 共有用のタイトルを返す
  def share_title_for
    case params[:type]
    when "event"
      "#{@event.display_name} タイムテーブル"
    when "my-timetable"
      "#{@user.name}の#{@event.display_name} マイタイムテーブル"
    end
  end

  # X共有用のテキストを返す
  def share_text_for
    case params[:type]
    when "event"
      "#{share_title_for}\n\n#{share_url_for}\n\nみんなのタイムテーブルで音楽フェスのタイムテーブルを作ろう！\n\n##{@event.display_name}\n#みんなのタイムテーブル"
    when "my-timetable"
      "#{share_title_for}\n\n#{share_url_for}\n\nみんなのタイムテーブルでマイタイムテーブルを作ろう！\n\n##{@event.display_name}\n#みんなのタイムテーブル"
    end
  end
end
