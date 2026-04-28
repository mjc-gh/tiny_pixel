# frozen_string_literal: true

module Sites
  class MembershipsController < ApplicationController
    before_action :authenticate_user!
    before_action :set_site
    before_action :authorize_site_admin!

    def index
      @memberships = @site.memberships.includes(:user).order(created_at: :desc)
    end

    def new
      @membership = @site.memberships.build
    end

    def create
      @membership = @site.memberships.build(role: create_params[:role])
      email = create_params[:email]

      return render_invitation_error if email_delivery_unsupported?(email)

      user, is_new_user = find_or_invite_user(email)
      return if user.nil?

      @membership.user = user
      save_membership_and_redirect(is_new_user)
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

    def create_params
      params.require(:membership).permit(:email, :role)
    end

    def email_delivery_unsupported?(email)
      User.find_by(email: email).nil? && !TinyPixel.email_delivery_supported?
    end

    def render_invitation_error
      @membership.errors.add(:base, t("sites.memberships.create.user_not_found"))
      render :new, status: :unprocessable_entity
    end

    def find_or_invite_user(email)
      user = User.find_by(email: email)
      return [user, false] if user.present?

      user = invite_new_user(email)
      [user, user.present?]
    end

    def invite_new_user(email)
      User.invite(email)
    rescue ActiveRecord::RecordInvalid => e
      e.record.errors.each { |error| @membership.errors.add(:base, error.full_message) }
      render :new, status: :unprocessable_entity
      nil
    end

    def save_membership_and_redirect(is_new_user)
      if @membership.save
        message_key = is_new_user ? "create.success_invited" : "create.success"
        flash[:notice] = t("sites.memberships.#{message_key}")
        redirect_to site_memberships_path(@site), status: :see_other
      else
        render :new, status: :unprocessable_entity
      end
    end
  end
end
