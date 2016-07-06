require 'active_support/log_subscriber'

module ActionTexter
  # Implements the ActiveSupport::LogSubscriber for logging notifications when
  # message is delivered.
  class LogSubscriber < ActiveSupport::LogSubscriber
    # An message was delivered.
    def deliver(event)
      info do
        recipients = Array(event.payload[:to]).join(', ')
        "Sent text message to #{recipients} (#{event.duration.round(1)}ms)"
      end

      debug { event.payload[:text] }
    end

    # An message was generated.
    def process(event)
      debug do
        texter = event.payload[:texter]
        action = event.payload[:action]
        "#{texter}##{action}: processed outbound text message in #{event.duration.round(1)}ms"
      end
    end

    # Use the logger configured for ActionTexter::Base.
    def logger
      ActionTexter::Base.logger
    end
  end
end

ActionTexter::LogSubscriber.attach_to :action_texter
