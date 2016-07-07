require 'delegate'

module ActionTexter
  # The <tt>ActionTexter::MessageDelivery</tt> class is used by
  # <tt>ActionTexter::Base</tt> when creating a new texter.
  # <tt>MessageDelivery</tt> is a wrapper (+Delegator+ subclass) around a lazy
  # created <tt>Text::Message</tt>. You can get direct access to the
  # <tt>Text::Message</tt>, deliver the message or schedule the message to be sent
  # through Active Job.
  #
  #   Notifier.welcome(User.first)               # an ActionTexter::MessageDelivery object
  #   Notifier.welcome(User.first).deliver_now   # sends the message
  #   Notifier.welcome(User.first).deliver_later # enqueue message delivery as a job through Active Job
  #   Notifier.welcome(User.first).message       # a Text::Message object
  class MessageDelivery < Delegator
    def initialize(texter_class, action, *args) #:nodoc:
      @texter_class, @action, @args = texter_class, action, args

      # The text is only processed if we try to call any methods on it.
      # Typical usage will leave it unloaded and call deliver_later.
      @processed_texter = nil
      @text_message = nil
    end

    # Method calls are delegated to the Text::Message that's ready to deliver.
    def __getobj__ #:nodoc:
      @text_message ||= processed_texter.message
    end

    # Unused except for delegator internals (dup, marshaling).
    def __setobj__(text_message) #:nodoc:
      @text_message = text_message
    end

    # Returns the resulting Text::Message
    def message
      __getobj__
    end

    # Was the delegate loaded, causing the texter action to be processed?
    def processed?
      @processed_texter || @text_message
    end

    # Enqueues the message to be delivered through Active Job. When the
    # job runs it will send the message using +deliver_now!+. That means
    # that the message will be sent bypassing checking +perform_deliveries+
    # and +raise_delivery_errors+, so use with caution.
    #
    #   Notifier.welcome(User.first).deliver_later!
    #   Notifier.welcome(User.first).deliver_later!(wait: 1.hour)
    #   Notifier.welcome(User.first).deliver_later!(wait_until: 10.hours.from_now)
    #
    # Options:
    #
    # * <tt>:wait</tt> - Enqueue the message to be delivered with a delay
    # * <tt>:wait_until</tt> - Enqueue the message to be delivered at (after) a specific date / time
    # * <tt>:queue</tt> - Enqueue the message on the specified queue
    def deliver_later!(options={})
      enqueue_delivery :deliver_now!, options
    end

    # Enqueues the message to be delivered through Active Job. When the
    # job runs it will send the message using +deliver_now+.
    #
    #   Notifier.welcome(User.first).deliver_later
    #   Notifier.welcome(User.first).deliver_later(wait: 1.hour)
    #   Notifier.welcome(User.first).deliver_later(wait_until: 10.hours.from_now)
    #
    # Options:
    #
    # * <tt>:wait</tt> - Enqueue the message to be delivered with a delay.
    # * <tt>:wait_until</tt> - Enqueue the message to be delivered at (after) a specific date / time.
    # * <tt>:queue</tt> - Enqueue the message on the specified queue.
    def deliver_later(options={})
      enqueue_delivery :deliver_now, options
    end

    # Delivers an message without checking +perform_deliveries+ and +raise_delivery_errors+,
    # so use with caution.
    #
    #   Notifier.welcome(User.first).deliver_now!
    #
    def deliver_now!
      processed_texter.handle_exceptions do
        message.deliver!
      end
    end

    # Delivers an message:
    #
    #   Notifier.welcome(User.first).deliver_now
    #
    def deliver_now
      processed_texter.handle_exceptions do
        message.deliver
      end
    end

    private
      # Returns the processed Texter instance. We keep this instance
      # on hand so we can delegate exception handling to it.
      def processed_texter
        @processed_texter ||= @texter_class.new.tap do |texter|
          texter.process @action, *@args
        end
      end

      def enqueue_delivery(delivery_method, options={})
        if processed?
          ::Kernel.raise "You've accessed the message before asking to " \
            "deliver it later, so you may have made local changes that would " \
            "be silently lost if we enqueued a job to deliver it. Why? Only " \
            "the texter method *arguments* are passed with the delivery job! " \
            "Do not access the message in any way if you mean to deliver it " \
            "later. Workarounds: 1. don't touch the message before calling " \
            "#deliver_later, 2. only touch the message *within your texter " \
            "method*, or 3. use a custom Active Job instead of #deliver_later."
        else
          args = @texter_class.name, @action.to_s, delivery_method.to_s, *@args
          ::ActionTexter::DeliveryJob.set(options).perform_later(*args)
        end
      end
  end
end
