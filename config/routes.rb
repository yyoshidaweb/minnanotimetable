Rails.application.routes.draw do
  # ユーザープロフィール用のルーティング
  resource :profile, only: [ :show, :edit, :update, :destroy ]

  # Deviseのルーティング設定でOmniauthコールバック用コントローラーを指定
  devise_for :users, controllers: {
    omniauth_callbacks: "users/omniauth_callbacks"
  }

  # ユーザー詳細ページ（/users/:username）
  resources :users, only: [ :show ], param: :username

  # トップページ
  root to: "static_pages#index"

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # イベントタグ名候補表示のための検索機能
  resources :event_name_tags, only: [] do
    collection do
      get :search   # /event_name_tags/search
    end
  end

  # イベント作成
  resources :events, only: [ :new, :create ]

  # イベント情報編集ページ（/events/:event_key/edit）
  resources :events, param: :event_key, only: [ :edit, :update ]

  # タイムテーブル編集ページ（/:event_key/edit）
  get "/:event_key/edit", to: "timetables#edit", as: :edit_timetable

  # イベント詳細ページ（/:event_key）
  get "/:event_key", to: "events#show", as: :show_timetable
end
