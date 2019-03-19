require_relative "boot"

require "rails"
# Pick the frameworks you want:
require "active_model/railtie"
require "active_job/railtie"
require "active_record/railtie"
require "active_storage/engine"
require "action_controller/railtie"
# require "action_mailer/railtie"
require "action_view/railtie"
# require "action_cable/engine"
require "sprockets/railtie"
require "rails/test_unit/railtie"
require "action_mailer/railtie"

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module ContentPublisher
  class Application < Rails::Application
    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 5.2

    # Settings in config/environments/* take precedence over those specified here.
    # Application configuration can go into files in config/initializers
    # -- all .rb files in that directory are automatically loaded after loading
    # the framework and any gems in your application.

    config.action_view.raise_on_missing_translations = true

    config.i18n.load_path += Dir[Rails.root.join("config", "locales", "**", "*.yml")]
    config.action_view.raise_on_missing_translations = true

    config.time_zone = "London"

    unless Rails.application.secrets.jwt_auth_secret
      raise "JWT auth secret is not configured. See config/secrets.yml"
    end

    config.after_initialize do
      config.action_mailer.notify_settings = {
        api_key: Rails.application.secrets.notify_api_key,
        template_id: ENV["GOVUK_NOTIFY_TEMPLATE_ID"],
      }
    end
  end
end
