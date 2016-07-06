module ActionTexter
  # Provides helper methods for ActionTexter::Base that can be used for easily
  # accessing texter or message instances.
  module TexterHelper
    # Access the texter instance.
    def texter
      @_controller
    end

    # Access the message instance.
    def message
      @_message
    end
  end
end
