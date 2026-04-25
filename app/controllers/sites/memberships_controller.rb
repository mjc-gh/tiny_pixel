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
      email = create_params[:email]
      role = create_params[:role]

      @membership = @site.memberships.build(role: role)

      user = User.find_by(email: email)
      is_new_user = user.nil?

      if user.nil? && !TinyPixel.email_delivery_supported?
        @membership.errors.add(:base, t("sites.memberships.create.user_not_found"))
        render :new, status: :unprocessable_entity
        return
      end

      if is_new_user
        temp_password = SecureRandom.urlsafe_base64(ReviseAuth.minimum_password_length)
        user = User.new(
          email: email,
          password: temp_password,
          password_confirmation: temp_password,
          password_reset_required: true,
          confirmed_at: Time.current
        )

        unless user.save
          render :new, status: :unprocessable_entity
          return
        end

        user.send_password_reset_instructions
      end

      @membership.user = user

      if @membership.save
        message_key = is_new_user ? "create.success_invited" : "create.success"
        flash[:notice] = t("sites.memberships.#{message_key}")
        redirect_to site_memberships_path(@site), status: :see_other
      else
        render :new, status: :unprocessable_entity
      end
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
  end
end
