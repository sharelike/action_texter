$:.unshift File.expand_path('../lib', __FILE__)
require 'action_texter/gem_version'

Gem::Specification.new do |s|
  s.platform    = Gem::Platform::RUBY
  s.name        = 'actiontexter'
  s.version     = ActionTexter::VERSION::STRING
  s.summary     = 'Text message composition and delivery framework (inspired from Action Mailer, part of Rails).'
  s.description = 'Text message on Rails. Compose, deliver, and test text message using the familiar controller/view pattern.'

  s.required_ruby_version = '>= 2.2.2'

  s.license = 'MIT'

  s.author   = 'Sharelike Inc.'
  s.email    = 'engineers@sharelike.asia'
  s.homepage = 'https://sharelike.asia'

  s.files        = Dir['README.rdoc', 'MIT-LICENSE', 'lib/**/*']
  s.require_path = 'lib'
  s.requirements << 'none'

  s.add_dependency 'actionpack', '~> 5.0'
  s.add_dependency 'actionview', '~> 5.0'
  s.add_dependency 'activejob',  '~> 5.0'
end
