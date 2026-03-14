class Users::OmniauthCallbacksController < Devise::OmniauthCallbacksController
  # Rememberableモジュールをインクルードして、remember_me メソッドを利用可能にする
  include Devise::Controllers::Rememberable
  # Googleから返ってきた認証情報を処理する
  def google_oauth2
    # Googleから取得した認証情報をもとにユーザーを検索 or 作成
    @user = User.from_omniauth(request.env["omniauth.auth"])

    if @user.persisted?
      # ログイン状態を保持するための remember_me クッキーを設定
      remember_me(@user)
      # DBに保存済みユーザーならログイン処理を実行
      sign_in_and_redirect @user, event: :authentication
      # ログイン成功メッセージを表示（ブラウザアクセス時のみ）
      set_flash_message(:notice, :success, kind: "Google") if is_navigational_format?
    else
      # 新規登録画面へリダイレクト＋エラーメッセージ表示
      redirect_to root_path, alert: "Googleログインに失敗しました"
    end
  end

  # 認証処理が失敗したときの共通ハンドラー
  def failure
    redirect_to root_path, alert: "Googleログインに失敗しました"
  end
end
