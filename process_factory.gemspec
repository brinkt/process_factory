# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'process_factory/version'

Gem::Specification.new do |spec|
  spec.name          = "process_factory"
  spec.version       = ProcessFactory::VERSION
  spec.authors       = ["Taylor Brink"]
  spec.email         = ["taylor@nanobasis.com"]

  spec.summary       = %q{Perform synchronized calculation across multiple threads or processes.}
  spec.homepage      = "https://github.com/brinkt/process_factory.git"
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  spec.bindir        = "bin"
  spec.require_paths = ["lib"]

  spec.add_development_dependency 'bundler', '~> 0'
  spec.add_development_dependency 'rake', '~> 0'
  spec.add_development_dependency 'rspec', '~> 0'
  spec.add_development_dependency 'pry', '~> 0'
end
