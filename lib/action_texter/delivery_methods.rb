require 'tmpdir'

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
      self.delivery_method  = :smtp

      add_delivery_method :smtp, Text::SMTP,
        address:              "localhost",
        port:                 25,
        domain:               'localhost.localdomain',
        user_name:            nil,
        password:             nil,
        authentication:       nil,
        enable_starttls_auto: true

      add_delivery_method :file, Text::FileDelivery,
        location: defined?(Rails.root) ? "#{Rails.root}/tmp/texts" : "#{Dir.tmpdir}/texts"

      add_delivery_method :sendtext, Text::Sendtext,
        location:  '/usr/sbin/sendtext',
        arguments: '-i'

      add_delivery_method :test, Text::TestTexter
    end

    # Helpers for creating and wrapping delivery behavior, used by DeliveryMethods.
    module ClassMethods
      # Provides a list of messages that have been delivered by Text::TestTexter
      delegate :deliveries, :deliveries=, to: Text::TestTexter

      # Adds a new delivery method through the given class using the given
      # symbol as alias and the default options supplied.
      #
      #   add_delivery_method :sendtext, Text::Sendtext,
      #     location:  '/usr/sbin/sendtext',
      #     arguments: '-i -t'
      def add_delivery_method(symbol, klass, default_options={})
        class_attribute(:"#{symbol}_settings") unless respond_to?(:"#{symbol}_settings")
        send(:"#{symbol}_settings=", default_options)
        self.delivery_methods = delivery_methods.merge(symbol.to_sym => klass).freeze
      end

      def wrap_delivery_behavior(text, method=nil, options=nil) # :nodoc:
        method ||= self.delivery_method
        text.delivery_handler = self

        case method
        when NilClass
          raise "Delivery method cannot be nil"
        when Symbol
          if klass = delivery_methods[method]
            text.delivery_method(klass, (send(:"#{method}_settings") || {}).merge(options || {}))
          else
            raise "Invalid delivery method #{method.inspect}"
          end
        else
          text.delivery_method(method)
        end

        text.perform_deliveries    = perform_deliveries
        text.raise_delivery_errors = raise_delivery_errors
      end
    end

    def wrap_delivery_behavior!(*args) # :nodoc:
      self.class.wrap_delivery_behavior(message, *args)
    end
  end
end