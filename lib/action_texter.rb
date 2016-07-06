require 'abstract_controller'
require 'action_texter/version'

# Common Active Support usage in Action Texter
require 'active_support/rails'
require 'active_support/core_ext/class'
require 'active_support/core_ext/module/attr_internal'
require 'active_support/core_ext/string/inflections'
require 'active_support/lazy_load_hooks'

module ActionTexter
  extend ::ActiveSupport::Autoload

  eager_autoload do
    autoload :Collector
  end

  autoload :Base
  autoload :DeliveryMethods
  autoload :InlinePreviewInterceptor
  autoload :TexterHelper
  autoload :Preview
  autoload :Previews, 'action_texter/preview'
  autoload :TestCase
  autoload :TestHelper
  autoload :MessageDelivery
  autoload :DeliveryJob
end

autoload :Mime, 'action_dispatch/http/mime_type'

ActiveSupport.on_load(:action_view) do
  ActionView::Base.default_formats ||= Mime::SET.symbols
  ActionView::Template::Types.delegate_to Mime
end
