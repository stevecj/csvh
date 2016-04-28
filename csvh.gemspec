# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'csvh/version'

Gem::Specification.new do |spec|
  spec.name          = "csvh"
  spec.version       = CSVH::VERSION
  spec.authors       = ["Steve Jorgensen"]
  spec.email         = ["stevej@stevej.name"]

  spec.summary       = "Convenient augmentations to handling of CSV files with header rows in Ruby"
  spec.homepage      = "https://github.com/stevecj/csvh"
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.11"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "rspec", "~> 3.0"
end
