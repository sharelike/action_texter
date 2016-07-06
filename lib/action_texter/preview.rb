require 'active_support/descendants_tracker'

module ActionTexter
  module Previews #:nodoc:
    extend ActiveSupport::Concern

    included do
      # Set the location of texter previews through app configuration:
      #
      #     config.action_texter.preview_path = "#{Rails.root}/lib/texter_previews"
      #
      mattr_accessor :preview_path, instance_writer: false

      # Enable or disable texter previews through app configuration:
      #
      #     config.action_texter.show_previews = true
      #
      # Defaults to true for development environment
      #
      mattr_accessor :show_previews, instance_writer: false

      # :nodoc:
      mattr_accessor :preview_interceptors, instance_writer: false
      self.preview_interceptors = [ActionTexter::InlinePreviewInterceptor]
    end

    module ClassMethods
      # Register one or more Interceptors which will be called before text is previewed.
      def register_preview_interceptors(*interceptors)
        interceptors.flatten.compact.each { |interceptor| register_preview_interceptor(interceptor) }
      end

      # Register an Interceptor which will be called before text is previewed.
      # Either a class or a string can be passed in as the Interceptor. If a
      # string is passed in it will be <tt>constantize</tt>d.
      def register_preview_interceptor(interceptor)
        preview_interceptor = case interceptor
          when String, Symbol
            interceptor.to_s.camelize.constantize
          else
            interceptor
          end

        unless preview_interceptors.include?(preview_interceptor)
          preview_interceptors << preview_interceptor
        end
      end
    end
  end

  class Preview
    extend ActiveSupport::DescendantsTracker

    class << self
      # Returns all texter preview classes.
      def all
        load_previews if descendants.empty?
        descendants
      end

      # Returns the text object for the given message name. The registered preview
      # interceptors will be informed so that they can transform the message
      # as they would if the text was actually being delivered.
      def call(message)
        preview = self.new
        message = preview.public_send(message)
        inform_preview_interceptors(message)
        message
      end

      # Returns all of the available message previews.
      def messages
        public_instance_methods(false).map(&:to_s).sort
      end

      # Returns true if the message exists.
      def message_exists?(message)
        messages.include?(message)
      end

      # Returns true if the preview exists.
      def exists?(preview)
        all.any?{ |p| p.preview_name == preview }
      end

      # Find a texter preview by its underscored class name.
      def find(preview)
        all.find{ |p| p.preview_name == preview }
      end

      # Returns the underscored name of the texter preview without the suffix.
      def preview_name
        name.sub(/Preview$/, '').underscore
      end

      protected
        def load_previews #:nodoc:
          if preview_path
            Dir["#{preview_path}/**/*_preview.rb"].each{ |file| require_dependency file }
          end
        end

        def preview_path #:nodoc:
          Base.preview_path
        end

        def show_previews #:nodoc:
          Base.show_previews
        end

        def inform_preview_interceptors(message) #:nodoc:
          Base.preview_interceptors.each do |interceptor|
            interceptor.previewing_message(message)
          end
        end
    end
  end
end
