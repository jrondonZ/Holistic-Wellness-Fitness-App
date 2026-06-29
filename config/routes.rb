Rails.application.routes.draw do
  # Public marketing front door
  root "welcome#index"

  # Authentication
  get  "signup", to: "users#new"
  post "signup", to: "users#create"
  get  "login",  to: "sessions#new"
  post "login",  to: "sessions#create"
  delete "logout", to: "sessions#destroy"
  get "logout", to: "sessions#destroy"
  resources :users, only: [ :new, :create, :destroy ]

  # Account settings + password
  get   "settings",          to: "settings#show", as: :settings
  patch "settings",          to: "settings#update"
  patch "settings/password", to: "settings#update_password", as: :settings_password
  resources :password_resets, only: [ :new, :create, :edit, :update ], param: :token

  # Legal acceptance (from the blocking modal) + public legal documents
  post "accept-legal", to: "legal_acceptances#create", as: :accept_legal
  get  "terms",   to: "pages#terms"
  get  "privacy", to: "pages#privacy"

  # First-run interactive tutorial
  post   "tutorial/complete", to: "tutorials#complete", as: :complete_tutorial
  delete "tutorial",          to: "tutorials#restart",  as: :restart_tutorial

  # In-app notifications
  resources :notifications, only: [ :index ] do
    collection { patch :read_all }
    member { patch :read }
  end

  # The chart (Epic/MyChart-style member health record)
  get "dashboard", to: "dashboard#index", as: :dashboard

  # Demographics, vitals baseline and care goals (one per member)
  resource :health_profile, only: [ :show, :edit, :update ]

  # Wellness — daily check-ins / vitals flowsheet
  resources :checkins

  # Diet — nutrition log
  resources :meal_entries

  # Fitness — logged workout activity
  resources :workout_logs

  # Fitness library — curated videos / workouts and multi-week routines (read-only)
  resources :workouts, only: [ :index, :show ]
  resources :routines, only: [ :index, :show ]

  # Education — holistic wellness & fitness articles (read-only)
  resources :articles, only: [ :index, :show ]

  # Scheduling — browse bookable services and manage appointments
  resources :services, only: [ :index, :show ]
  resources :appointments, only: [ :index, :new, :create, :show ] do
    member do
      patch :cancel
      get :calendar # iCalendar (.ics) download
    end
  end

  # HIPAA & compliance training
  resources :trainings, only: [ :index, :show ] do
    member { post :complete }
  end

  # Secure messaging — one thread per assigned provider
  get  "messages",              to: "messages#index", as: :messages
  get  "messages/:provider_id", to: "messages#show",  as: :message_thread
  post "messages/:provider_id", to: "messages#create"

  # -------------------------------------------------------------- Admin portal
  get "admin", to: "admin/dashboard#index", as: :admin_root
  namespace :admin do
    resources :users, only: [ :index, :show, :new, :create, :edit, :update, :destroy ] do
      resources :assessments, only: [ :create, :update, :destroy ]
      resources :care_assignments, only: [ :create, :destroy ]
    end
    resources :appointments, only: [ :index, :show, :update ]
    resources :conversations, only: [ :index, :show ] do
      member { post :reply }
    end
    resources :services, only: [ :index, :new, :create, :edit, :update, :destroy ]
    get "analytics", to: "analytics#index"

    # Owner-only care-team management
    get    "team",     to: "team#index",   as: :team
    post   "team",     to: "team#create"
    patch  "team/:id", to: "team#update",  as: :team_member
    delete "team/:id", to: "team#destroy"
  end

  # Sage — the holistic wellness AI assistant (member-facing chat endpoint)
  namespace :api do
    post "ai/chat", to: "ai#chat"
  end

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  get "up" => "rails/health#show", as: :rails_health_check
end
