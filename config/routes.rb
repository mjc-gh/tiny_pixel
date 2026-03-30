Rails.application.routes.draw do
  root "home#show"

  revise_auth
  # Pixel ingestion ingestion
  get "/_/pixel.gif" => "v1/pixels#create", as: :v1_pixels

  # Default health check
  get "/up" => "rails/health#show", as: :rails_health_check
end
