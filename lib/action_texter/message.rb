module ActionTexter
  class Message
    attr_reader :to
    attr_accessor :body
    attr_accessor :charset
    attr_accessor :delivery_handler
    attr_accessor :delivery_method
    attr_accessor :perform_deliveries
    attr_accessor :raise_delivery_errors

    def initialize(*args, &block)
      @to = []
      @body = nil
      @charset = 'UTF-8'

      @delivery_handler = nil
      @delivery_method = nil
      @perform_deliveries = true
      @raise_delivery_errors = true
    end

    def to=(val)
      @to = Array(val)
    end

    # Delivers an message object
    def deliver
      if delivery_handler
        delivery_handler.deliver_text(self) { do_delivery }
      else
        do_delivery
      end
      self
    end

    # This method bypasses checking perform_deliveries and raise_delivery_errors,
    # so use with caution.
    def deliver!
      raise "Delivery method cannot be nil" if delivery_method.nil?
      response = delivery_method.deliver!(self)
      delivery_method.settings[:return_response] ? response : self
    end

    private

    def do_delivery
      begin
        if perform_deliveries && delivery_method
          delivery_method.deliver!(self)
        end
      rescue => e
        raise e if raise_delivery_errors
      end
    end
  end
end
