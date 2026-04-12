# frozen_string_literal: true

class HomeController < ApplicationController
  def show
    redirect_to sites_path if user_signed_in?
  end
end
