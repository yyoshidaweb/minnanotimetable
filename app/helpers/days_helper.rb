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
end
