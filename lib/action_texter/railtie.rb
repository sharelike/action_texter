require 'active_job/railtie'
require 'action_texter'
require 'rails'
require 'abstract_controller/railties/routes_helpers'

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

      options.cache_store ||= Rails.cache

      ActiveSupport.on_load(:action_texter) do
        include AbstractController::UrlFor
        extend ::AbstractController::Railties::RoutesHelpers.with(app.routes, false)
        include app.routes.mounted_helpers

        options.each { |k,v| send("#{k}=", v) }
      end

      views = paths["app/views"].existent
      unless views.empty?
        ActiveSupport.on_load(:action_texter) do
          prepend_view_path views
        end
      end
    end

    initializer "action_texter.compile_config_methods" do
      ActiveSupport.on_load(:action_texter) do
        config.compile_methods! if config.respond_to?(:compile_methods!)
      end
    end

    config.before_configuration do |app|
      app.config.paths.add "app/texters", eager_load: true
    end
  end
end
