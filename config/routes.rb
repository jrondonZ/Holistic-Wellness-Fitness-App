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

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  get "up" => "rails/health#show", as: :rails_health_check
end
