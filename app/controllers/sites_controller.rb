# frozen_string_literal: true

class SitesController < ApplicationController
  before_action :authenticate_user!

  def index
    @sites = current_user.sites.order(created_at: :desc)
  end
end
