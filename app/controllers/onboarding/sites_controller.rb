# frozen_string_literal: true

class Onboarding::SitesController < ApplicationController
  before_action :authenticate_user!
  before_action :redirect_if_has_sites, only: [:new, :create]

  def new
    @site = Site.new
  end

  def create
    @site = Site.new(site_params)

    if @site.save
      current_user.memberships.create!(site: @site, role: :admin)
      render :create
    else
      render :new, status: :unprocessable_entity
    end
  end

  private

  def redirect_if_has_sites
    redirect_to sites_path if current_user.sites.exists?
  end

  def site_params
    params.require(:site).permit(:name)
  end
end
