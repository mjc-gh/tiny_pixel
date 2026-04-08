# frozen_string_literal: true

Rails.application.routes.draw do
  root "home#show"

  revise_auth

  resources :sites, only: [:index, :show, :edit, :update] do
    scope module: :sites do
      resource :instructions, only: [:show]
      resources :pathnames, only: [:index]
      resources :page_views, only: [:index]
      resources :visitors, only: [:index]
      resources :avg_duration, only: [:index]
      resources :bounce_rate, only: [:index]
    end
  end
  # Pixel ingestion ingestion
  get "/_/pixel.gif" => "v1/pixels#create", as: :v1_pixels

  # Default health check
  get "/up" => "rails/health#show", as: :rails_health_check
end
