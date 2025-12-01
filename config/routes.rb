Rails.application.routes.draw do
  get "events/show"
  # ユーザープロフィール用のルーティング
  resource :profile, only: [ :show, :edit, :update, :destroy ]

  # Deviseのルーティング設定でOmniauthコールバック用コントローラーを指定
  devise_for :users, controllers: {
    omniauth_callbacks: "users/omniauth_callbacks"
  }

  # ユーザー詳細ページ（/users/:username）
  resources :users, only: [ :show ], param: :username

  get "static_pages/index"

  # トップページ
  root to: "static_pages#index"

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # イベント詳細ページ（/:event_key）
  get "/:event_key", to: "events#show", as: :event
end
