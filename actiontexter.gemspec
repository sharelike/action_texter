require_relative 'lib/actiontexter/gem_version'

Gem::Specification.new do |s|
  s.platform    = Gem::Platform::RUBY
  s.name        = 'actiontexter'
  s.version     = ActionTexter::VERSION::STRING
  s.summary     = 'Text message composition and delivery framework (inspired from Action Mailer).'
  s.description = 'Text message on Rails. Compose, deliver, and test text message using the familiar controller/view pattern.'

  s.required_ruby_version = '>= 2.2.2'

  s.license = 'MIT'

  s.author   = 'Sharelike Inc.'
  s.email    = 'dev@sharelike.asia'
  s.homepage = 'http://sharelike.asia'

  s.files        = Dir['README.rdoc', 'LICENSE', 'lib/**/*']
  s.require_path = 'lib'
  s.requirements << 'none'
end
