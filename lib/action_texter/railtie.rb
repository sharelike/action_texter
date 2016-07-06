require 'active_job/railtie'
require "action_texter"
require "rails"
require "abstract_controller/railties/routes_helpers"

module ActionTexter
  class Railtie < Rails::Railtie # :nodoc:
    config.action_texter = ActiveSupport::OrderedOptions.new
    config.eager_load_namespaces << ActionTexter

    initializer "action_texter.logger" do
      ActiveSupport.on_load(:action_texter) { self.logger ||= Rails.logger }
    end

    initializer "action_texter.set_configs" do |app|
      paths   = app.config.paths
      options = app.config.action_texter

      if app.config.force_ssl
        options.default_url_options ||= {}
        options.default_url_options[:protocol] ||= 'https'
      end

      options.assets_dir      ||= paths["public"].first
      options.javascripts_dir ||= paths["public/javascripts"].first
      options.stylesheets_dir ||= paths["public/stylesheets"].first
      options.cache_store ||= Rails.cache

      # make sure readers methods get compiled
      options.asset_host          ||= app.config.asset_host
      options.relative_url_root   ||= app.config.relative_url_root

      ActiveSupport.on_load(:action_texter) do
        include AbstractController::UrlFor
        extend ::AbstractController::Railties::RoutesHelpers.with(app.routes, false)
        include app.routes.mounted_helpers

        register_interceptors(options.delete(:interceptors))
        register_observers(options.delete(:observers))

        options.each { |k,v| send("#{k}=", v) }
      end
    end

    initializer "action_texter.compile_config_methods" do
      ActiveSupport.on_load(:action_texter) do
        config.compile_methods! if config.respond_to?(:compile_methods!)
      end
    end
  end
end
