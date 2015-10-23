# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'primes/utils/version'

Gem::Specification.new do |spec|
  spec.name          = "primes-utils"
  spec.version       = Primes::Utils::VERSION
  spec.authors       = ["Jabari Zakiya"]
  spec.email         = ["jzakiya@gmail.com"]

  spec.summary       = %q{suite of extremely fast utility methods for testing and generating primes}
  spec.description   = %q{Methods: prime?, primemr?, primes, primesf, primesmr, primescnt, primescntf, primescntmr, primenth|nthprime, factors|prime_division, primes_utils}
  spec.homepage      = "https://github.com/jzakiya/primes-utils"

  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]
  spec.license       = "GPLv2+"
  spec.required_ruby_version = ">= 1.8.7"

  #if spec.respond_to?(:metadata)
  #  spec.metadata['allowed_push_host'] = "TODO: Set to 'http://mygemserver.com' to prevent pushes to rubygems.org, or delete to allow pushes to any server."
  #end

  spec.add_development_dependency "bundler", "~> 1.9"
  spec.add_development_dependency "rake", "~> 10.0"
end
