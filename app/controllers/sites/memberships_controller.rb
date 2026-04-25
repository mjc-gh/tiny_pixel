# frozen_string_literal: true

module Sites
  class MembershipsController < ApplicationController
    before_action :authenticate_user!
    before_action :set_site
    before_action :authorize_site_admin!

    def index
      @memberships = @site.memberships.includes(:user).order(created_at: :desc)
    end

    def edit
      @membership = @site.memberships.find(params[:id])
    end

    def update
      @membership = @site.memberships.find(params[:id])

      if @membership.user == current_user && @membership.admin?
        flash[:alert] = t("sites.memberships.update.cannot_demote_self")
        render :edit, status: :unprocessable_entity
        return
      end

      if @membership.update(membership_params)
        flash[:notice] = t("sites.memberships.update.success")
        redirect_to site_memberships_path(@site), status: :see_other
      else
        render :edit, status: :unprocessable_entity
      end
    end

    def destroy
      @membership = @site.memberships.find(params[:id])

      if @membership.user == current_user
        flash[:alert] = t("sites.memberships.destroy.cannot_remove_self")
        redirect_to site_memberships_path(@site), status: :see_other
        return
      end

      if @membership.destroy
        flash[:notice] = t("sites.memberships.destroy.success")
      end
      redirect_to site_memberships_path(@site), status: :see_other
    end

    private

    def membership_params
      params.require(:membership).permit(:role)
    end
  end
end
