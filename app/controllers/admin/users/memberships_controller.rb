# frozen_string_literal: true

module Admin
  module Users
    class MembershipsController < AdminController
      def new
        @user = User.find(params[:user_id])
        @membership = @user.memberships.build
        @available_sites = Site.where.not(id: @user.site_ids)
      end

      def create
        @user = User.find(params[:user_id])
        @membership = @user.memberships.build(membership_params)

        if @membership.save
          redirect_to admin_user_path(@user), notice: t("admin.users.memberships.create.success"), status: :see_other
        else
          @available_sites = Site.where.not(id: @user.site_ids)
          render :new, status: :unprocessable_entity
        end
      end

      def destroy
        @user = User.find(params[:user_id])
        @membership = @user.memberships.find(params[:id])
        @membership.destroy
        redirect_to admin_user_path(@user), notice: t("admin.users.memberships.destroy.success"), status: :see_other
      end

      private

      def membership_params
        params.require(:membership).permit(:site_id, :role)
      end
    end
  end
end
