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

  # ステージタグ名候補表示のための検索機能
  resources :stage_name_tags, only: [] do
    collection do
      get :search
    end
  end

  # 出演者タグ名候補表示のための検索機能
  resources :performer_name_tags, only: [] do
    collection do
      get :search
    end
  end

  # イベント関連
  resources :events, param: :event_key, only: [ :index, :new, :create, :show, :edit, :update, :destroy ] do
    resources :days, only: [ :index, :new, :create, :destroy ]
    resources :stages, only: [ :index, :new, :create, :show, :edit, :update, :destroy ]
    resources :performers, only: [ :index, :new, :create, :show, :edit, :update, :destroy ]
    resources :performances, only: [ :new, :create, :edit, :update, :destroy ]
  end


  # タイムテーブル編集ページ（/:event_key/edit）
  get "/:event_key/edit", to: "timetables#edit", as: :edit_timetable

  # イベント詳細ページ（/:event_key）
  get "/:event_key", to: "timetables#show", as: :show_timetable
end
