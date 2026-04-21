# frozen_string_literal: true

class Users::PasswordResetsController < ApplicationController
  before_action :authenticate_user!
  before_action :require_password_reset_flag, only: [:edit, :update]

  def edit
    @user = current_user
  end

  def update
    @user = current_user

    if @user.update(password_params)
      @user.update_column(:password_reset_required, false)
      redirect_to root_path, notice: t(".success")
    else
      render :edit, status: :unprocessable_entity
    end
  end

  private

  def require_password_reset_flag
    redirect_to root_path unless current_user.password_reset_required?
  end

  def password_params
    params.require(:user).permit(:password, :password_confirmation)
  end
end
