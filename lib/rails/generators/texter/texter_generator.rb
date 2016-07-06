module Rails
  module Generators
    class TexterGenerator < NamedBase
      source_root File.expand_path("../templates", __FILE__)

      argument :actions, type: :array, default: [], banner: "method method"

      check_class_collision suffix: "Texter"

      def create_texter_file
        template "texter.rb", File.join('app/texters', class_path, "#{file_name}_texter.rb")

        in_root do
          if self.behavior == :invoke && !File.exist?(application_texter_file_name)
            template 'application_texter.rb', application_texter_file_name
          end
        end
      end

      hook_for :template_engine

      protected
        def file_name
          @_file_name ||= super.gsub(/_texter/i, '')
        end

      private
        def application_texter_file_name
          @_application_texter_file_name ||= if mountable_engine?
                                             "app/texters/#{namespaced_path}/application_texter.rb"
                                           else
                                             "app/texters/application_texter.rb"
                                           end
        end
    end
  end
end
