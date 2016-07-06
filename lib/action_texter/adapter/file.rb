require 'fileutils'
require_relative '../check_delivery_params'

module ActionTexter
  module Adapter
    class File
      include ActionTexter::CheckDeliveryParams

      def initialize(settings = {})
        @settings = {
          location: './texts'
        }.merge! settings
      end

      attr_accessor :settings

      def deliver!(message)
        recipients, content = check_delivery_params message

        ::FileUtils.mkdir_p settings[:location]

        recipients.each do |to|
          ::File.open(::File.join(settings[:location], ::File.basename(to.to_s)), 'a+') do |f|
            f.write("#{content}\r\n")
          end
        end
      end
    end
  end
end
