# frozen_string_literal: true

class Environ
  MissingEnvVar = Class.new(KeyError)

  class << self
    def [](key)
      ENV.fetch(key.to_s)
    rescue KeyError => e
      # TODO output better error messages on how to configure Tiny Pixel
      raise MissingEnvVar, <<~ERR.squish
        The #{key} env var is not defined and is required for running this application.
      ERR
    end
  end
end
