require 'tmpdir'
require_relative 'adapter/file'
require_relative 'adapter/test_adapter'

module ActionTexter
  # This module handles everything related to text delivery, from registering
  # new delivery methods to configuring the text object to be sent.
  module DeliveryMethods
    extend ActiveSupport::Concern

    included do
      class_attribute :delivery_methods, :delivery_method

      # Do not make this inheritable, because we always want it to propagate
      cattr_accessor :raise_delivery_errors
      self.raise_delivery_errors = true

      cattr_accessor :perform_deliveries
      self.perform_deliveries = true

      cattr_accessor :deliver_later_queue_name
      self.deliver_later_queue_name = :texters

      self.delivery_methods = {}.freeze
      self.delivery_method  = :file

      add_delivery_method :file, Adapter::File,
        location: defined?(Rails.root) ? "#{Rails.root}/tmp/texters" : "#{Dir.tmpdir}/texters"

      add_delivery_method :test, Adapter::TestAdapter
    end

    # Helpers for creating and wrapping delivery behavior, used by DeliveryMethods.
    module ClassMethods
      # Provides a list of messages that have been delivered by Text::TestTexter
      delegate :deliveries, :deliveries=, to: Adapter::TestAdapter

      # Adds a new delivery method through the given class using the given
      # symbol as alias and the default options supplied.
      def add_delivery_method(symbol, klass, default_options = {})
        class_attribute(:"#{symbol}_settings") unless respond_to?(:"#{symbol}_settings")
        send(:"#{symbol}_settings=", default_options)
        self.delivery_methods = delivery_methods.merge(symbol.to_sym => klass).freeze
      end

      def wrap_delivery_behavior(message, method = nil, options = nil) # :nodoc:
        method ||= self.delivery_method
        message.delivery_handler = self

        case method
        when NilClass
          raise "Delivery method cannot be nil"
        when Symbol
          if klass = delivery_methods[method]
            message.delivery_method = klass.new (send(:"#{method}_settings") || {}).merge(options || {})
          else
            raise "Invalid delivery method #{method.inspect}"
          end
        else
          message.delivery_method = method
        end

        message.perform_deliveries    = perform_deliveries
        message.raise_delivery_errors = raise_delivery_errors
      end
    end

    def wrap_delivery_behavior!(*args) # :nodoc:
      self.class.wrap_delivery_behavior(message, *args)
    end
  end
end
