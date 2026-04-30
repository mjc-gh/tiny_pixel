# frozen_string_literal: true

class Admin::SitesController < AdminController
  def index
    @sites = Site.all.order(:created_at)
  end

  def new
    @site = Site.new
  end

  def create
    @site = Site.new(site_params)

    if @site.save
      redirect_to admin_site_path(@site), notice: t("admin.sites.create.success")
    else
      render :new, status: :unprocessable_entity
    end
  end

  def show
    @site = Site.find(params[:id])
    @memberships = @site.memberships.includes(:user).order(created_at: :desc)
  end

  def edit
    @site = Site.find(params[:id])
  end

  def update
    @site = Site.find(params[:id])

    if @site.update(site_params)
      redirect_to admin_site_path(@site), notice: t("admin.sites.update.success")
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @site = Site.find(params[:id])
    @site.destroy
    redirect_to admin_sites_path, notice: t("admin.sites.destroy.success"), status: :see_other
  end

  private

  def site_params
    params.require(:site).permit(
      :name,
      :salt_duration,
      :display_hostname,
      :session_timeout_minutes,
      :stats_retention_duration,
      :stats_retention_unit
    )
  end
end
