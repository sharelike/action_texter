require 'active_support/core_ext/object/blank'

module ActionTexter
  module CheckDeliveryParams
    def check_delivery_params(message)
      recipients = Array(message.to)
        .compact
        .map { |recipient| recipient.to_s.strip }
        .delete_if { |recipient| recipient.blank? }
        .uniq
      raise ArgumentError.new 'Recipient is required to send a text message' if message.to.blank?
      raise ArgumentError.new 'Message body is required to send a text message' if message.body.blank?

      [recipients, message.body]
    end
  end
end
