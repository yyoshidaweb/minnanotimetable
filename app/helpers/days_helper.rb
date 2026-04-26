module DaysHelper
  # フォームタイプごとのselect_tagを返す
  def day_select_name(form_type)
    case form_type
    when "performance"
      "performance[day_id]"
    else
      "day_id"
    end
  end

  # フォームタイプごとにinclude_blankの内容を変える
  def day_select_include_blank(form_type)
    case form_type
    when "performance"
      "未定"
    else
      "開催日を選択"
    end
  end
end
