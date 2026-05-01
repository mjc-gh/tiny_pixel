# frozen_string_literal: true

Rails.application.routes.draw do
  root "home#show"

  # Override registrations controller
  get "sign_up", to: "users/registrations#new"
  post "sign_up", to: "users/registrations#create"

  namespace :users do
    resource :password_reset, only: [:edit, :update]
    resource :invitation, only: [:show]
  end

  revise_auth

  namespace :onboarding do
    resources :sites, only: [:new, :create]
  end

  resources :sites, only: [:index, :show, :new, :create, :edit, :update] do
    scope module: :sites do
      # Site management
      resources :memberships, only: [:index, :new, :create, :edit, :update, :destroy]

      # Site dashboard
      resource :instructions, only: [:show]
      resources :pathnames, only: [:index]
      resources :page_views, only: [:index]
      resources :visitors, only: [:index]
      resources :avg_duration, only: [:index]
      resources :bounce_rate, only: [:index]
      resources :dimensions, only: [:index]
    end
  end

  # System Admin
  namespace :admin do
    get "/" => "dashboard#index"
    resources :sites
    resources :users, only: [:index, :new, :create, :show, :edit, :update, :destroy] do
      resources :memberships, only: [:new, :create, :destroy], module: :users
      resource :resend_invitation, only: [:create], module: :users
    end
    resource :system_settings, only: [:show] do
      resource :allowed_registration_domains, only: [:update], module: :system_settings
    end
  end

  # PWA routes
  get "manifest" => "rails/pwa#manifest", as: :pwa_manifest

  # Pixel ingestion ingestion
  get "/_/pixel.gif" => "v1/pixels#create", as: :v1_pixels

  # Default health check
  get "/up" => "rails/health#show", as: :rails_health_check

  mount LetterOpenerWeb::Engine, at: "/letter_opener" if Rails.env.development?
end
