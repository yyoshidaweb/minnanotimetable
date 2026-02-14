class ApplicationController < ActionController::Base
  # プレビュー環境で自動的にプレビューユーザーとしてログインする（deviseのdestroyアクション以外）
  before_action :auto_login_preview_user, unless: :devise_destroy_action?
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

  private

  # プレビュー環境で自動的にテストユーザーとしてログインする処理
  def auto_login_preview_user
    return unless ENV["IS_PULL_REQUEST"] == "true" # Preview環境以外なら何もしない
    return if session[:preview_logged_out] # ログアウトしている場合は何もしない
    return if current_user.present? # 既にログイン済なら何もしない
    user = User.find_by(email: "user1@example.com")
    return unless user # テストユーザーが存在しない場合は何もしない
    sign_in(user) # Deviseでログイン
  end

  # Deviseのdestroyアクションかどうかを判定するヘルパーメソッド
  def devise_destroy_action?
    controller_name == "sessions" && action_name == "destroy"
  end
end
