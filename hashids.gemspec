# encoding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'hashids'

Gem::Specification.new do |gem|
  gem.name          = "hashids"
  gem.version       = Hashids::VERSION
  gem.authors       = ["Peter Hellberg"]
  gem.email         = ["peter@c7.se"]
  gem.summary       = %q{Generate YouTube-like hashes from one or many numbers.}
  gem.description   = %q{Use hashids when you do not want to expose your database ids to the user.}
  gem.homepage      = "https://github.com/peterhellberg/hashids.rb"

  gem.required_ruby_version = '>= 1.9.3'

  gem.files         = `git ls-files`.split($/)
  gem.test_files    = gem.files.grep(%r{^(spec)/})
  gem.require_paths = ["lib"]
end
