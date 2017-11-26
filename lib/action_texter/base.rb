require 'active_support/core_ext/string/inflections'
require 'active_support/core_ext/hash/except'
require 'active_support/core_ext/module/anonymous'

require 'action_texter/log_subscriber'
require 'action_texter/rescuable'

module ActionTexter
  # Action Texter allows you to send message from your application using a texter model and views.
  #
  # = Texter Models
  #
  # To use Action Texter, you need to create a texter model.
  #
  #   $ rails generate texter Notifier
  #
  # The generated model inherits from <tt>ApplicationTexter</tt> which in turn
  # inherits from <tt>ActionTexter::Base</tt>. A texter model defines methods
  # used to generate an message message. In these methods, you can setup variables to be used in
  # the texter views, options on the text itself such as the <tt>:charset</tt>.
  #
  #   class ApplicationTexter < ActionTexter::Base
  #     default charset: 'UTF-8'
  #     layout 'texter'
  #   end
  #
  #   class NotifierTexter < ApplicationTexter
  #     def welcome(recipient)
  #       @account = recipient
  #       text(to: recipient.phone_number)
  #     end
  #   end
  #
  # Within the texter method, you have access to the following methods:
  #
  # * <tt>text</tt> - Allows you to specify message to be sent.
  #
  # The hash passed to the text method allows you to specify any option that will accept.
  #
  # = Texter views
  #
  # Like Action Controller, each texter class has a corresponding view directory in which each
  # method of the class looks for a template with its name.
  #
  # To define a template to be used with a texter, create an <tt>.erb</tt> file with the same
  # name as the method in your texter model. For example, in the texter defined above, the template at
  # <tt>app/views/notifier_texter/welcome.text.erb</tt> would be used to generate the message.
  #
  # Variables defined in the methods of your texter model are accessible as instance variables in their
  # corresponding view.
  #
  # Etexts by default are sent in plain text, so a sample view for our model example might look like this:
  #
  #   Hi <%= @account.name %>,
  #   Thanks for joining our service! Please check back often.
  #
  # You can even use Action View helpers in these views. For example:
  #
  #   You got a new note!
  #   <%= truncate(@note.body, length: 25) %>
  #
  # If you need to access the subject, from or the recipients in the view, you can do that through message object:
  #
  #   You got a new note from <%= message.from %>!
  #   <%= truncate(@note.body, length: 25) %>
  #
  # = Generating URLs
  #
  # URLs can be generated in texter views using <tt>url_for</tt> or named routes. Unlike controllers from
  # Action Pack, the texter instance doesn't have any context about the incoming request, so you'll need
  # to provide all of the details needed to generate a URL.
  #
  # When using <tt>url_for</tt> you'll need to provide the <tt>:host</tt>, <tt>:controller</tt>, and <tt>:action</tt>:
  #
  #   <%= url_for(host: "example.com", controller: "welcome", action: "greeting") %>
  #
  # When using named routes you only need to supply the <tt>:host</tt>:
  #
  #   <%= users_url(host: "example.com") %>
  #
  # You should use the <tt>named_route_url</tt> style (which generates absolute URLs) and avoid using the
  # <tt>named_route_path</tt> style (which generates relative URLs), since clients reading the text will
  # have no concept of a current URL from which to determine a relative path.
  #
  # It is also possible to set a default host that will be used in all texters by setting the <tt>:host</tt>
  # option as a configuration option in <tt>config/application.rb</tt>:
  #
  #   config.action_texter.default_url_options = { host: "example.com" }
  #
  # By default when <tt>config.force_ssl</tt> is true, URLs generated for hosts will use the HTTPS protocol.
  #
  # = Sending text
  #
  # Once a texter action and template are defined, you can deliver your message or defer its creation and
  # delivery for later:
  #
  #   NotifierTexter.welcome(User.first).deliver_now # sends the message
  #   text = NotifierTexter.welcome(User.first)      # => an ActionTexter::MessageDelivery object
  #   text.deliver_now                               # generates and sends the message now
  #
  # The <tt>ActionTexter::MessageDelivery</tt> class is a wrapper around a delegate that will call
  # your method to generate the text. If you want direct access to the delegator, or <tt>ActionTexter::Message</tt>,
  # you can call the <tt>message</tt> method on the <tt>ActionTexter::MessageDelivery</tt> object.
  #
  #   NotifierTexter.welcome(User.first).message     # => a ActionTexter::Message object
  #
  # Action Texter is nicely integrated with Active Job so you can generate and send messages in the background
  # (example: outside of the request-response cycle, so the user doesn't have to wait on it):
  #
  #   NotifierTexter.welcome(User.first).deliver_later # enqueue the message sending to Active Job
  #
  # Note that <tt>deliver_later</tt> will execute your method from the background job.
  #
  # You never instantiate your texter class. Rather, you just call the method you defined on the class itself.
  # All instance methods are expected to return a message object to be sent.
  #
  # = Default Hash
  #
  # Action Texter provides some intelligent defaults for your messages, these are usually specified in a
  # default method inside the class definition:
  #
  #   class NotifierTexter < ApplicationTexter
  #     default charset: 'Big5'
  #   end
  #
  # You can pass in any option value. Out of the box, <tt>ActionTexter::Base</tt> sets the following:
  #
  # * <tt>charset:      "UTF-8"</tt>
  #
  # Action Texter also supports passing <tt>Proc</tt> objects into the default hash, so you
  # can define methods that evaluate as the message is being generated:
  #
  #   class NotifierTexter < ApplicationTexter
  #     default to: Proc.new { my_method }
  #
  #     private
  #
  #       def my_method
  #         'some complex call'
  #       end
  #   end
  #
  # Note that the proc is evaluated right at the start of the text message generation, so if you
  # set something in the default hash using a proc, and then set the same thing inside of your
  # texter method, it will get overwritten by the texter method.
  #
  # It is also possible to set these default options that will be used in all texters through
  # the <tt>default_options=</tt> configuration in <tt>config/application.rb</tt>:
  #
  #    config.action_texter.default_options = { charset: "UTF-8" }
  #
  # = Callbacks
  #
  # You can specify callbacks using before_action and after_action for configuring your messages.
  # This may be useful, for example, when you want to add default variables for all
  # messages sent out by a certain texter class:
  #
  #   class NotifierTexter < ApplicationTexter
  #     before_action :set_title!
  #
  #     def welcome
  #       text
  #     end
  #
  #     private
  #
  #       def set_title!
  #         @title = "hello"
  #       end
  #   end
  #
  # Callbacks in Action Texter are implemented using
  # <tt>AbstractController::Callbacks</tt>, so you can define and configure
  # callbacks in the same manner that you would use callbacks in classes that
  # inherit from <tt>ActionController::Base</tt>.
  #
  # Note that unless you have a specific reason to do so, you should prefer
  # using <tt>before_action</tt> rather than <tt>after_action</tt> in your
  # Action Texter classes so that options are parsed properly.
  #
  # = Configuration options
  #
  # These options are specified on the class level, like
  # <tt>ActionTexter::Base.raise_delivery_errors = true</tt>
  #
  # * <tt>default_options</tt> - You can pass this in at a class level as well as within the class itself as
  #   per the above section.
  #
  # * <tt>logger</tt> - the logger is used for generating information on the texting run if available.
  #   Can be set to +nil+ for no logging. Compatible with both Ruby's own +Logger+ and Log4r loggers.
  #
  # * <tt>file_settings</tt> - Allows you to override options for the <tt>:file</tt> delivery method.
  #   * <tt>:location</tt> - The directory into which messages will be written. Defaults to the application
  #     <tt>tmp/texts</tt>.
  #
  # * <tt>raise_delivery_errors</tt> - Whether or not errors should be raised if the message fails to be delivered.
  #
  # * <tt>delivery_method</tt> - Defines a delivery method. Possible values are <tt>:smtp</tt> (default),
  #   <tt>:sendtext</tt>, <tt>:test</tt>, and <tt>:file</tt>. Or you may provide a custom delivery method
  #   object e.g. +MyOwnDeliveryMethodClass+. See the Text gem documentation on the interface you need to
  #   implement for a custom delivery agent.
  #
  # * <tt>perform_deliveries</tt> - Determines whether messages are actually sent from Action Texter when you
  #   call <tt>.deliver</tt> on an message message or on an Action Texter method. This is on by default but can
  #   be turned off to aid in functional testing.
  #
  # * <tt>deliveries</tt> - Keeps an array of all the messages sent out through the Action Texter with
  #   <tt>delivery_method :test</tt>. Most useful for unit and functional testing.
  #
  # * <tt>deliver_later_queue_name</tt> - The name of the queue used with <tt>deliver_later</tt>.
  class Base < AbstractController::Base
    include DeliveryMethods
    include Rescuable

    abstract!

    include AbstractController::Rendering

    include AbstractController::Logger
    include AbstractController::Helpers
    include AbstractController::Translation
    include AbstractController::Callbacks
    include AbstractController::Caching

    include ActionView::Layouts

    PROTECTED_IVARS = AbstractController::Rendering::DEFAULT_PROTECTED_INSTANCE_VARIABLES + [:@_action_has_layout]

    def _protected_ivars # :nodoc:
      PROTECTED_IVARS
    end

    helper ActionTexter::TexterHelper

    class_attribute :default_params
    self.default_params = {
      charset: "UTF-8"
    }.freeze

    class << self
      # Returns the name of current texter. This method is also being used as a path for a view lookup.
      # If this is an anonymous texter, this method will return +anonymous+ instead.
      def texter_name
        @texter_name ||= anonymous? ? "anonymous" : name.underscore
      end
      # Allows to set the name of current texter.
      attr_writer :texter_name
      alias :controller_path :texter_name

      # Sets the defaults through app configuration:
      #
      #     config.action_texter.default(charset: "Big5")
      #
      # Aliased by ::default_options=
      def default(value = nil)
        self.default_params = default_params.merge(value).freeze if value
        default_params
      end
      # Allows to set defaults through app configuration:
      #
      #    config.action_texter.default_options = { charset: "Big5" }
      alias :default_options= :default

      # Wraps an message delivery inside of <tt>ActiveSupport::Notifications</tt> instrumentation.
      #
      # This method is actually called by the <tt>ActionTexter::Message</tt> object itself
      # through a callback when you call <tt>:deliver</tt> on the <tt>ActionTexter::Message</tt>,
      # calling +deliver_text+ directly and passing a <tt>ActionTexter::Message</tt> will do
      # nothing except tell the logger you sent the message.
      def deliver_text(message) #:nodoc:
        ActiveSupport::Notifications.instrument("deliver.action_texter") do |payload|
          payload[:texter] = name
          payload[:to] = message.to
          payload[:body] = message.body
          yield # Let Message do the delivery actions
        end
      end

      protected

      def method_missing(method_name, *args) # :nodoc:
        if action_methods.include?(method_name.to_s)
          MessageDelivery.new(self, method_name, *args)
        else
          super
        end
      end

      private

      def respond_to_missing?(method, include_all = false) #:nodoc:
        action_methods.include?(method.to_s)
      end
    end

    attr_internal :message

    # Instantiate a new texter object. If +method_name+ is not +nil+, the texter
    # will be initialized according to the named method. If not, the texter will
    # remain uninitialized.
    def initialize
      super
      @_text_was_called = false
      @_message = Message.new
    end

    def process(method_name, *args) #:nodoc:
      payload = {
        texter: self.class.name,
        action: method_name
      }

      ActiveSupport::Notifications.instrument("process.action_texter", payload) do
        super
        @_message = NullMessage.new unless @_text_was_called
      end
    end

    class NullMessage #:nodoc:
      def to; [] end
      def body; '' end

      def respond_to?(string, include_all = false)
        true
      end

      def method_missing(*args)
        nil
      end
    end

    # Returns the name of the texter object.
    def texter_name
      self.class.texter_name
    end

    # The main method that creates the message and renders the message templates. There are
    # two ways to call this method, with a block, or without a block.
    #
    # It accepts a option hash. This hash allows you to specify options used in an message,
    # these are:
    #
    # * +:to+ - Who the message is destined for, can be a string of phone number, or an array
    #   of numbers.
    # * +:charset+ - The charset of the message.
    #
    # You can set default values for any of the above options by using the ::default class method:
    #
    #  class Notifier < ActionTexter::Base
    #    default charset: 'UTF-8'
    #  end
    #
    # It will find the .txt/.text template in the view paths using by default
    # the texter name and the method name that it is being called from,
    # it will then create body for the template intelligently, and return a fully
    # prepared <tt>ActionTexter::Message</tt> ready to call <tt>:deliver</tt> on to send.
    #
    # For example:
    #
    #   class Notifier < ActionTexter::Base
    #     def welcome
    #       text(to: '+886900000000')
    #     end
    #   end
    #
    # Will look for all templates at "app/views/notifier" with name "welcome".
    # If no welcome template exists, it will raise an ActionView::MissingTemplate error.
    #
    # However, those can be customized:
    #
    #   text(template_path: 'notifications', template_name: 'another')
    #
    # And now it will look for all templates at "app/views/notifications" with name "another".
    #
    def text(options = {})
      return message if @_text_was_called

      options = apply_defaults(options)

      message.charset = options[:charset]

      # Set configure delivery behavior
      wrap_delivery_behavior!(options[:delivery_method], options[:delivery_method_options])

      message.to = options[:to]

      # Render the templates
      message.body = response(options)
      @_text_was_called = true

      message
    end

    protected

    # Text messages do not support relative path links.
    def self.supports_path?
      false
    end

    private

    def apply_defaults(options)
      default_values = self.class.default.map do |key, value|
        [
          key,
          value.is_a?(Proc) ? instance_eval(&value) : value
        ]
      end.to_h

      options.reverse_merge(default_values)
    end

    def response(options)
      if options[:body]
        options.delete(:body)
      else
        response_from_templates(options)
      end
    end

    # Now we only support .text/.txt format for SMS
    def response_from_templates(options)
      templates_path = options[:templates_path] || self.class.texter_name
      templates_name = options[:templates_name] || action_name

      templates_paths = Array(templates_path)
      template = lookup_context.find(templates_name, templates_paths, nil, [], { formats: [:txt, :text] })

      render(template: template)
    end

    # This and #instrument_name is for caching instrument
    def instrument_payload(key)
      {
        texter: texter_name,
        key: key
      }
    end

    def instrument_name
      "action_texter"
    end

    ActiveSupport.run_load_hooks(:action_texter, self)
  end
end
