require 'active_job'

module ActionTexter
  # Provides helper methods for testing Action Texter, including #assert_messages
  # and #assert_no_messages.
  module TestHelper
    include ActiveJob::TestHelper

    # Asserts that the number of messages sent matches the given number.
    #
    #   def test_messages
    #     assert_messages 0
    #     ContactTexter.welcome.deliver_now
    #     assert_messages 1
    #     ContactTexter.welcome.deliver_now
    #     assert_messages 2
    #   end
    #
    # If a block is passed, that block should cause the specified number of
    # messages to be sent.
    #
    #   def test_messages_again
    #     assert_messages 1 do
    #       ContactTexter.welcome.deliver_now
    #     end
    #
    #     assert_messages 2 do
    #       ContactTexter.welcome.deliver_now
    #       ContactTexter.welcome.deliver_now
    #     end
    #   end
    def assert_messages(number)
      if block_given?
        original_count = ActionTexter::Base.deliveries.size
        yield
        new_count = ActionTexter::Base.deliveries.size
        assert_equal number, new_count - original_count, "#{number} messages expected, but #{new_count - original_count} were sent"
      else
        assert_equal number, ActionTexter::Base.deliveries.size
      end
    end

    # Asserts that no messages have been sent.
    #
    #   def test_messages
    #     assert_no_messages
    #     ContactTexter.welcome.deliver_now
    #     assert_messages 1
    #   end
    #
    # If a block is passed, that block should not cause any messages to be sent.
    #
    #   def test_messages_again
    #     assert_no_messages do
    #       # No messages should be sent from this block
    #     end
    #   end
    #
    # Note: This assertion is simply a shortcut for:
    #
    #   assert_messages 0
    def assert_no_messages(&block)
      assert_messages 0, &block
    end

    # Asserts that the number of messages enqueued for later delivery matches
    # the given number.
    #
    #   def test_messages
    #     assert_enqueued_messages 0
    #     ContactTexter.welcome.deliver_later
    #     assert_enqueued_messages 1
    #     ContactTexter.welcome.deliver_later
    #     assert_enqueued_messages 2
    #   end
    #
    # If a block is passed, that block should cause the specified number of
    # messages to be enqueued.
    #
    #   def test_messages_again
    #     assert_enqueued_messages 1 do
    #       ContactTexter.welcome.deliver_later
    #     end
    #
    #     assert_enqueued_messages 2 do
    #       ContactTexter.welcome.deliver_later
    #       ContactTexter.welcome.deliver_later
    #     end
    #   end
    def assert_enqueued_messages(number, &block)
      assert_enqueued_jobs number, only: ActionTexter::DeliveryJob, &block
    end

    # Asserts that no messages are enqueued for later delivery.
    #
    #   def test_no_messages
    #     assert_no_enqueued_messages
    #     ContactTexter.welcome.deliver_later
    #     assert_enqueued_messages 1
    #   end
    #
    # If a block is provided, it should not cause any messages to be enqueued.
    #
    #   def test_no_messages
    #     assert_no_enqueued_messages do
    #       # No messages should be enqueued from this block
    #     end
    #   end
    def assert_no_enqueued_messages(&block)
      assert_no_enqueued_jobs only: ActionTexter::DeliveryJob, &block
    end
  end
end
