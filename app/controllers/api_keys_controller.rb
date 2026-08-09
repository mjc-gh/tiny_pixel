# frozen_string_literal: true

class ApiKeysController < ApplicationController
  before_action :authenticate_user!
  before_action :set_api_key, only: :destroy

  def index
    @api_keys = current_user.api_keys.order(created_at: :desc)
    no_store if flash[:api_key_token].present?
  end

  def new
    @api_key = current_user.api_keys.build
  end

  def create
    @api_key = current_user.api_keys.build(api_key_params)

    if @api_key.save
      flash[:api_key_token] = @api_key.token
      no_store
      redirect_to api_keys_path
    else
      render :new, status: :unprocessable_entity
    end
  end

  def destroy
    @api_key.destroy!
    redirect_to api_keys_path, status: :see_other, notice: t("api_keys.destroy.success")
  end

  private

  def set_api_key
    @api_key = current_user.api_keys.find(params[:id])
  end

  def api_key_params
    params.require(:api_key).permit(:name, :expires_at)
  end

  def no_store
    response.headers["Cache-Control"] = "no-store"
  end
end
