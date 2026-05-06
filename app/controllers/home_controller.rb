# frozen_string_literal: true

class HomeController < ApplicationController
  def show
    redirect_to sites_path if user_signed_in?
  end

  private

  def cold_start?
    User.none?
  end
  helper_method :cold_start?
end
