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

  autoload :Base
  autoload :DeliveryMethods
  autoload :TexterHelper
  autoload :TestCase
  autoload :TestHelper
  autoload :MessageDelivery
  autoload :DeliveryJob
end
