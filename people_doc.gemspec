# frozen_string_literal: true

lib = File.expand_path('lib', __dir__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'people_doc/version'

Gem::Specification.new do |spec|
  spec.name = 'people_doc'
  spec.version = PeopleDoc::VERSION
  spec.authors = ['Joseph Bridgwater-Rowe']
  spec.email = ['joe@westernmilling.com']
  spec.summary = 'Basic PeopleDoc REST API client'
  spec.homepage = 'https://github.com/westernmilling/people_doc'
  spec.license = 'MIT'
  spec.files = `git ls-files -z`.split("\x0").reject do |f|
    f.match(%r{^(test|spec|features)/})
  end
  spec.bindir = 'exe'
  spec.executables = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']
  spec.add_runtime_dependency 'httparty'
  spec.add_development_dependency 'bundler', '~> 1.16'
  spec.add_development_dependency 'factory_bot'
  spec.add_development_dependency 'faker'
  spec.add_development_dependency 'rake', '~> 10.0'
  spec.add_development_dependency 'rspec', '~> 3.0'
  spec.add_development_dependency 'rspec_junit_formatter'
  spec.add_development_dependency 'rubocop', '0.54.0'
  spec.add_development_dependency 'simplecov'
  spec.add_development_dependency 'webmock'
end
