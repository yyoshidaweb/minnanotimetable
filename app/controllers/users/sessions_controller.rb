class Users::SessionsController < Devise::SessionsController
  # ログアウト処理をオーバーライドして、プレビュー環境でログアウトしたときにセッションにフラグを立てる
  def destroy
    if preview_environment?
      session[:preview_logged_out] = true # ← ここに書く
    end
    super
  end

  private

  # プレビュー環境かどうかを判定するヘルパーメソッド
  def preview_environment?
    Rails.env.production? && ENV["IS_PULL_REQUEST"] == "true"
  end
end
