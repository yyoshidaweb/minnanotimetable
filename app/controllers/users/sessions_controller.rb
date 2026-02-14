class Users::SessionsController < Devise::SessionsController
  # ログアウト処理をオーバーライドして、プレビュー環境でログアウトしたときにセッションにフラグを立てる
  def destroy
    if preview_environment?
      session[:preview_logged_out] = true
    end
    super
  end

  private

  # プレビュー環境かどうかを判定するヘルパーメソッド
  def preview_environment?
    ENV["IS_PULL_REQUEST"] == "true"
  end
end
