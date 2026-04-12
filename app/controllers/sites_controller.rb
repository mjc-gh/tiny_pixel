# frozen_string_literal: true

class SitesController < ApplicationController
  include FilterStats

  before_action :authenticate_user!
  before_action :set_site, only: [:show, :edit, :update]

  def index
    @sites = current_user.sites.order(created_at: :desc)
  end

  def show
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
    params.require(:site).permit(:salt_duration, :display_hostname)
  end
end
