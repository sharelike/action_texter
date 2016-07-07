require 'active_support/test_case'
require 'rails-dom-testing'

module ActionTexter
  class NonInferrableTexterError < ::StandardError
    def initialize(name)
      super "Unable to determine the texter to test from #{name}. " +
        "You'll need to specify it using tests YourTexter in your " +
        "test case definition"
    end
  end

  class TestCase < ActiveSupport::TestCase
    module ClearTestDeliveries
      extend ActiveSupport::Concern

      included do
        setup :clear_test_deliveries
        teardown :clear_test_deliveries
      end

      private

      def clear_test_deliveries
        if ActionTexter::Base.delivery_method == :test
          ActionTexter::Base.deliveries.clear
        end
      end
    end

    module Behavior
      extend ActiveSupport::Concern

      include ActiveSupport::Testing::ConstantLookup
      include TestHelper
      include Rails::Dom::Testing::Assertions::SelectorAssertions
      include Rails::Dom::Testing::Assertions::DomAssertions

      included do
        class_attribute :_texter_class
        setup :initialize_test_deliveries
        setup :set_expected_text
        teardown :restore_test_deliveries
      end

      module ClassMethods
        def tests(texter)
          case texter
          when String, Symbol
            self._texter_class = texter.to_s.camelize.constantize
          when Module
            self._texter_class = texter
          else
            raise NonInferrableTexterError.new(texter)
          end
        end

        def texter_class
          if texter = self._texter_class
            texter
          else
            tests determine_default_texter(name)
          end
        end

        def determine_default_texter(name)
          texter = determine_constant_from_test_name(name) do |constant|
            Class === constant && constant < ActionTexter::Base
          end
          raise NonInferrableTexterError.new(name) if texter.nil?
          texter
        end
      end

      protected

        def initialize_test_deliveries # :nodoc:
          set_delivery_method :test
          @old_perform_deliveries = ActionTexter::Base.perform_deliveries
          ActionTexter::Base.perform_deliveries = true
          ActionTexter::Base.deliveries.clear
        end

        def restore_test_deliveries # :nodoc:
          restore_delivery_method
          ActionTexter::Base.perform_deliveries = @old_perform_deliveries
        end

        def set_delivery_method(method) # :nodoc:
          @old_delivery_method = ActionTexter::Base.delivery_method
          ActionTexter::Base.delivery_method = method
        end

        def restore_delivery_method # :nodoc:
          ActionTexter::Base.deliveries.clear
          ActionTexter::Base.delivery_method = @old_delivery_method
        end

        def set_expected_text # :nodoc:
          @expected = Text.new
          @expected.content_type ["text", "plain", { "charset" => charset }]
          @expected.mime_version = '1.0'
        end

      private

        def charset
          "UTF-8"
        end

        def encode(subject)
          Text::Encodings.q_value_encode(subject, charset)
        end

        def read_fixture(action)
          IO.readlines(File.join(Rails.root, 'test', 'fixtures', self.class.texter_class.name.underscore, action))
        end
    end

    include Behavior
  end
end
