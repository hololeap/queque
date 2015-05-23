# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'queque/version'

Gem::Specification.new do |spec|
  spec.name          = 'queque'
  spec.version       = Queque::VERSION
  spec.authors       = ['hololeap']
  spec.email         = ['hololeap@gmail.com']

  spec.summary       = 'A Redis-backed queue'
  spec.description   = 'A simple Redis-backed queue, similar in its functionality to Ruby\'s Queue class'
  spec.homepage      = 'https://github.com/hololeap/queque'
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  spec.require_paths = ["lib"]

  spec.add_development_dependency 'bundler', '~> 1.9'
  spec.add_development_dependency 'rake', '~> 10.0'

  spec.add_runtime_dependency 'redis-objects', '~> 0'
end
