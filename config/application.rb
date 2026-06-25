require_relative "boot"

require "rails/all"

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module HolisticChart
  class Application < Rails::Application
    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 8.1

    # Please, add to the `ignore` list any other `lib` subdirectories that do
    # not contain `.rb` files, or that should not be reloaded or eager loaded.
    # Common ones are `templates`, `generators`, or `middleware`, for example.
    config.autoload_lib(ignore: %w[assets tasks])

    # Holistic Wellness Fitness LLC is based in Meriden, CT.
    config.time_zone = "Eastern Time (US & Canada)"

    # The app ships static brand images via Propshaft and does not use Active
    # Storage variants, so disable variant processing (the image_processing /
    # libvips gem isn't bundled). This silences the precompile/boot warning.
    config.active_storage.variant_processor = :disabled
  end
end
