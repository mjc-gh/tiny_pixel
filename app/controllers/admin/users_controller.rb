# frozen_string_literal: true

class Admin::UsersController < AdminController
  def index
    @users = User.all.order(:created_at)
  end

  def new
    @user = User.new
  end

  def create
    temp_password = SecureRandom.urlsafe_base64(ReviseAuth.minimum_password_length)
    @user = User.new(
      email: user_params[:email],
      password: temp_password,
      password_confirmation: temp_password,
      password_reset_required: true,
      confirmed_at: Time.current
    )

    if @user.save
      redirect_to admin_user_path(@user), flash: { temp_password: temp_password }
    else
      render :new, status: :unprocessable_entity
    end
  end

  def show
    @user = User.find(params[:id])
    @temp_password = flash[:temp_password]
  end

  private

  def user_params
    params.require(:user).permit(:email)
  end
end
