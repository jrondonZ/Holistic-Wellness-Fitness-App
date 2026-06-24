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

  # First-run walkthrough + legal acceptance
  resource :onboarding, only: [ :show, :update ], controller: "onboarding"

  # Public legal documents
  get "terms",   to: "pages#terms"
  get "privacy", to: "pages#privacy"

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

  # Secure messaging with the care team (member side — their own thread)
  resources :messages, only: [ :index, :create ]

  # -------------------------------------------------------------- Admin portal
  get "admin", to: "admin/dashboard#index", as: :admin_root
  namespace :admin do
    resources :users, only: [ :index, :show ] do
      resources :assessments, only: [ :create, :update, :destroy ]
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

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  get "up" => "rails/health#show", as: :rails_health_check
end
