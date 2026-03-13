Rails.application.routes.draw do
  # ユーザープロフィール用のルーティング
  resource :profile, only: [ :show, :edit, :update, :destroy ]

  # Deviseのルーティング設定でOmniauthコールバック用コントローラーを指定
  devise_for :users, controllers: {
    omniauth_callbacks: "users/omniauth_callbacks"
  }

  # プレビュー環境でのログイン用ルーティング
  post "/preview_login", to: "preview_sessions#create"

  # ユーザー詳細ページ（/users/:username）
  get "/u/:username", to: "users#show", as: :show_user

  # トップページ
  root to: "home#index"

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
    resources :stages, only: [ :index, :new, :create, :show, :edit, :update, :destroy ] do
      collection do
        get :sort   # ステージを並び替えページ /events/:event_key/stages/sort
        patch :update_sort  # ステージ並び替え処理 /events/:event_key/stages/update_sort
      end
    end
    resources :performers, only: [ :index, :new, :create, :show, :edit, :update, :destroy ]
    resources :performances, only: [ :new, :create, :edit, :update, :destroy ]
  end

  # 出演情報のお気に入り登録・解除のルーティング
  resources :performance_favorites, only: [ :create, :destroy ]
  # 出演者単位で出演情報を一括お気に入り登録する機能のルーティング
  resources :performer_favorites, only: [ :create ]
  # 出演者単位で出演情報を一括お気に入り解除する機能のルーティング
  delete "/performer_favorites", to: "performer_favorites#destroy"

  get "/share/:event_key", to: "share#show", as: :share_event

  # 利用規約・プライバシーポリシー
  get "/terms", to: "static_pages#terms"
  get "/privacy", to: "static_pages#privacy"

  # イベント詳細ページ（/:event_key）
  get "/t/:event_key", to: "timetables#show", as: :show_timetable
end
