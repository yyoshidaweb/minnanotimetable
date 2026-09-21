class StaticPagesController < ApplicationController
  # 利用規約ページ
  def terms
    @page_title = "利用規約"
    @back_path = root_path
  end

  # プライバシーポリシーページ
  def privacy
    @page_title = "プライバシーポリシー"
    @back_path = root_path
  end
end
