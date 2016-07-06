require_relative 'gem_version'

module ActionTexter
  # Returns the version of the currently loaded Action Texter as a
  # <tt>Gem::Version</tt>.
  def self.version
    gem_version
  end
end