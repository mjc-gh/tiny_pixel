# frozen_string_literal: true

class SitesController < ApplicationController
  include FilterStats

  before_action :authenticate_user!
  before_action :set_site, only: [:show, :edit, :update]

  def index
    @sites = current_user.sites.order(created_at: :desc)
    redirect_to new_onboarding_site_path if @sites.empty?
  end

  def show
  end

  def new
    @site = Site.new
  end

  def create
    @site = Site.new(site_params)

    if @site.save
      current_user.memberships.create!(site: @site, role: :admin)
      redirect_to @site, notice: t("sites.create.success")
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @site.update(site_params)
      redirect_to @site, notice: t("sites.update.success")
    else
      render :edit, status: :unprocessable_entity
    end
  end

  private

  def set_site
    @site = current_user.sites.find(params[:id])
  end

  def site_params
    params.require(:site).permit(:name, :salt_duration, :display_hostname)
  end
end
