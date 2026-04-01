# frozen_string_literal: true

class SitesController < ApplicationController
  include IntervalStats

  before_action :authenticate_user!
  before_action :set_site, only: [:show]

  def index
    @sites = current_user.sites.order(created_at: :desc)
  end

  def show
  end

  private

  def set_site
    @site = current_user.sites.find(params[:id])
  end
end
