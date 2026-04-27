require_relative "boot"

require "rails/all"

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module TinyPixel
  class Application < Rails::Application
    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 8.0

    config.generators.helper = false

    # Please, add to the `ignore` list any other `lib` subdirectories that do
    # not contain `.rb` files, or that should not be reloaded or eager loaded.
    # Common ones are `templates`, `generators`, or `middleware`, for example.
    config.autoload_lib(ignore: %w[assets tasks])

    # Setup runtime settings
    config.runtime_settings = config_for(:tiny_pixel)

    # NOTE: Avoids the need for image_processing
    config.active_storage.variant_processor = :disabled
  end

  class << self
    def email_delivery_supported?
      Rails.application.config.runtime_settings.action_mailer_delivery.in? %w[smtp postmark]
    end

    def maxmind_db
      @geo_db ||= build_maxmind_db
    end

    private

    def build_maxmind_db
      path = Rails.root.join("storage", "GeoLite2-Country.mmdb").to_s
      return NullGeodb.new unless File.exist?(path)

      MaxMind::DB.new(path, mode: MaxMind::DB::MODE_MEMORY)
    rescue MaxMind::DB::InvalidDatabaseError
      NullGeodb.new
    end
  end
end
