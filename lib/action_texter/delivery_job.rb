require 'active_job'

module ActionTexter
  # The <tt>ActionTexter::DeliveryJob</tt> class is used when you
  # want to send messages outside of the request-response cycle.
  #
  # Exceptions are rescued and handled by the texter class.
  class DeliveryJob < ActiveJob::Base # :nodoc:
    queue_as { ActionTexter::Base.deliver_later_queue_name }

    rescue_from StandardError, with: :handle_exception_with_texter_class

    def perform(texter, text_method, delivery_method, *args) #:nodoc:
      texter.constantize.public_send(text_method, *args).send(delivery_method)
    end

    private
      # "Deserialize" the texter class name by hand in case another argument
      # (like a Global ID reference) raised DeserializationError.
      def texter_class
        if texter = Array(@serialized_arguments).first || Array(arguments).first
          texter.constantize
        end
      end

      def handle_exception_with_texter_class(exception)
        if klass = texter_class
          klass.handle_exception exception
        else
          raise exception
        end
      end
  end
end
