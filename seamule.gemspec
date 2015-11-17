# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'seamule/version'

Gem::Specification.new do |spec|
  spec.name = 'seamule'
  spec.version = SeaMule::VERSION
  spec.authors = ['Pablo Cárdenas']
  spec.email = ['pcardenasoliveros@gmail.com']

  spec.summary = %q{SeaMule is a Redis-backed Ruby library for creating jobs assigning them to clients and reducing them later}
  spec.description = %q{SeaMule is a Redis-backed Ruby library for creating jobs assigning them to clients and reducing them later}
  spec.homepage = 'https://github.com/pablo-co/seamule'
  spec.license = 'MIT'

  spec.files = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  spec.bindir = 'bin'
  spec.executables = ['seamule-server']
  spec.require_paths = ['lib']

  spec.add_development_dependency 'bundler', '~> 1.10'
  spec.add_development_dependency 'rake', '~> 10.0'
  spec.add_development_dependency 'minitest'

  spec.add_dependency 'multi_json', '~> 1.11.2'
  spec.add_dependency 'sinatra', '>= 0.9.2'
  spec.add_dependency 'redis-namespace', '~> 1.5.1'
  spec.add_dependency 'vegas', '~> 0.1.2'
  spec.add_dependency 'mono_logger', '>= 1.1.0'
end
