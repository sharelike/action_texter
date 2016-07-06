require_relative '../check_delivery_params'

module ActionTexter
  module Adapter
    class TestAdapter
      include ActionTexter::CheckDeliveryParams

      # Provides a store of all the text messages sent with the TestAdapter so you can check them.
      def self.deliveries
        @@deliveries ||= []
      end

      # Allows you to over write the default deliveries store from an array to some other object.
      # If you just want to clear the store, call TestAdapter.deliveries.clear.
      def self.deliveries=(val)
        @@deliveries = val
      end

      def initialize(settings = {})
        @settings = settings.dup
      end

      attr_accessor :settings

      def deliver!(message)
        check_delivery_params message
        self.class.delveries << message
      end
    end
  end
end
