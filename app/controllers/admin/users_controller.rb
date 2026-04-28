# frozen_string_literal: true

class Admin::UsersController < AdminController
  def index
    @users = User.all.order(:created_at)
  end

  def new
    @user = User.new
  end

  def create
    if invite_method?
      @user = User.invite(user_params[:email])
      redirect_to admin_users_path, notice: t("admin.users.create.success_invited")
    else
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
  rescue ActiveRecord::RecordInvalid => e
    @user = e.record
    render :new, status: :unprocessable_entity
  end

  def show
    @user = User.find(params[:id])
    @temp_password = flash[:temp_password]
    @memberships = @user.memberships.includes(:site).order(created_at: :desc)
  end

  def edit
    @user = User.find(params[:id])
    @memberships = @user.memberships.includes(:site).order(created_at: :desc)
  end

  def update
    @user = User.find(params[:id])

    if regenerate_password_params[:regenerate_password] == "true"
      temp_password = SecureRandom.urlsafe_base64(ReviseAuth.minimum_password_length)
      @user.update!(password: temp_password, password_confirmation: temp_password, password_reset_required: true)
      redirect_to admin_user_path(@user), flash: { temp_password: temp_password }, notice: t("admin.users.update.password_regenerated")
    else
      redirect_to admin_users_path
    end
  end

  def destroy
    @user = User.find(params[:id])
    @user.destroy
    redirect_to admin_users_path, notice: t("admin.users.destroy.success"), status: :see_other
  end

  private

  def user_params
    params.require(:user).permit(:email)
  end

  def regenerate_password_params
    params.require(:user).permit(:regenerate_password)
  end

  def invite_method?
    TinyPixel.email_delivery_supported? && params[:creation_method] == "invite"
  end
end
