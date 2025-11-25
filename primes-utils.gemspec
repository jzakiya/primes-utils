# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'primes/utils/version'
require 'rake'

Gem::Specification.new do |spec|
  spec.name          = "primes-utils"
  spec.version       = Primes::Utils::VERSION
  spec.authors       = ["Jabari Zakiya"]
  spec.email         = ["jzakiya@gmail.com"]

  spec.summary       = %q{suite of extremely fast utility methods for testing and generating primes}
  spec.description   = %q{Methods: prime?, primemr?, primes, primesmr, primescnt, primescntmr, primenth|nthprime, factors|prime_division, factors1, next_prime, prev_prime, primes_utils}
  spec.homepage      = "https://github.com/jzakiya/primes-utils"

  spec.files          = FileList['lib/primes/utils.rb', 'lib/primes/utils/*.rb','bin/*', 'README.md', 'Gemfile', 'Rakefile', 'CODE_OF_CONDUCT.md', 'primes-utils-3.0.0.gemspec']
  spec.require_paths = ["lib"]
  spec.license       = "LGPL-2.0-or-later"
  spec.required_ruby_version = ">= 3.0.0"

  spec.add_dependency "bitarray", "~> 1.3", ">= 1.3.1"
  spec.add_development_dependency "bundler", "~> 1.9"
  spec.add_development_dependency "rake", "~> 10.0"
end
