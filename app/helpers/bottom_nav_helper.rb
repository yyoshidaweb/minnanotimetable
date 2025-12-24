module BottomNavHelper
  # 下部タブメニューのアイテムを生成する
  def bottom_nav_item(path:, icon:, label:)
    active = current_page?(path)

    link_to path,
      class: "flex flex-col items-center gap-0.5 #{active ? 'text-black font-semibold' : 'text-gray-500'}" do
      safe_join([
        content_tag(
          :span,
          icon,
          class: "material-symbols-outlined #{active ? "font-variation-settings-['FILL'_1]" : ''}"
        ),
        content_tag(:span, label)
      ])
    end
  end
end
