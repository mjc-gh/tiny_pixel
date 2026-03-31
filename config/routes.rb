# frozen_string_literal: true

Rails.application.routes.draw do
  root "home#show"

  revise_auth

  resources :sites, only: [:index]
  # Pixel ingestion ingestion
  get "/_/pixel.gif" => "v1/pixels#create", as: :v1_pixels

  # Default health check
  get "/up" => "rails/health#show", as: :rails_health_check
end
