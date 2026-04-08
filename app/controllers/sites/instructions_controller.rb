# frozen_string_literal: true

module Sites
  class InstructionsController < ApplicationController
    before_action :authenticate_user!
    before_action :set_site

    def show
      @component = SetupInstructionsComponent.new(site: @site, request: request)
      render :show
    end

    private

    def set_site
      @site = current_user.sites.find(params[:site_id])
    end
  end
end
