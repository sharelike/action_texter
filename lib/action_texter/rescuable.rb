module ActionTexter #:nodoc:
  # Provides `rescue_from` for texters. Wraps texter action processing,
  # text job processing, and text delivery.
  module Rescuable
    extend ActiveSupport::Concern
    include ActiveSupport::Rescuable

    class_methods do
      def handle_exception(exception) #:nodoc:
        rescue_with_handler(exception) || raise(exception)
      end
    end

    def handle_exceptions #:nodoc:
      yield
    rescue => exception
      rescue_with_handler(exception) || raise
    end

    private
      def process(*)
        handle_exceptions do
          super
        end
      end
  end
end
