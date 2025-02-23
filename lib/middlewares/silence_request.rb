# frozen_string_literal: true

module Middlewares
  class SilenceRequest
    def initialize(app, paths:)
      @app, @paths = app, paths
    end

    def call(env)
      if env["PATH_INFO"].in? @paths
        Rails.logger.silence { @app.call(env) }
      else
        @app.call(env)
      end
    end
  end
end
