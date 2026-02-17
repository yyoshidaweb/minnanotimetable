class ApplicationController < ActionController::Base
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  unless Rails.env.development?
      # 本番・ステージングでのみ最新ブラウザのみ許可
      allow_browser versions: :modern
  end

  # Changes to the importmap will invalidate the etag for HTML responses
  stale_when_importmap_changes

  # 未ログイン時はログイン画面ではなくトップページへリダイレクトされるようにオーバーライド
  def authenticate_user!
    unless user_signed_in?
      redirect_to root_path
    else
      super
    end
  end

  # プレビュー環境かどうかを判定するヘルパーメソッド
  def self.preview_environment?
    Rails.env.production? && ENV["IS_PULL_REQUEST"] == "true"
  end

  # インスタンスメソッドとしてもpreview_environment?を使用できるようにする
  def preview_environment?
    self.class.preview_environment?
  end
  # ビューでpreview_environment?メソッドを使用できるようにする
  helper_method :preview_environment?
end
