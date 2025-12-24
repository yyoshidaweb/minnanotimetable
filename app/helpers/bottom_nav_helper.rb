module BottomNavHelper
  # 下部タブ用：選択中なら material-symbols-filled を返す
  # path: 判定対象のパス
  def bottom_tab_filled_class(path)
    "material-symbols-filled" if current_page?(path)
  end
end
