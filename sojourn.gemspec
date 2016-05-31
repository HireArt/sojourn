lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'sojourn/version'

Gem::Specification.new do |spec|
  spec.name          = 'sojourn'
  spec.version       = Sojourn::VERSION
  spec.authors       = ['HireArt']
  spec.email         = ['product@hireart.com']
  spec.summary       = 'Simple user source tracking for Rails.'
  spec.description   = %(
Sojourn tracks site visitors and sources, with the ability to recognise
multiple sources per visitor. Each time a new source is detected,
sojourn tracks the referer, utm data, and logged-in user (if any)).gsub("\n", ' ')
  spec.homepage      = 'https://github.com/HireArt/sojourn'
  spec.license       = 'MIT'

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(/^bin/) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(/^(test|spec|features)/)
  spec.require_paths = ['lib']

  spec.add_development_dependency 'bundler', '~> 1.7'
  spec.add_development_dependency 'rake', '~> 10.0'
  spec.add_development_dependency 'rspec', '~> 3.4.0'
  spec.add_development_dependency 'rspec-its', '~> 1.2.0'
  spec.add_development_dependency 'sqlite3', '~> 1.3.0'
  spec.add_development_dependency 'codeclimate-test-reporter', '~> 0.4.8'

  spec.add_dependency 'browser', '~> 0.8.0'
  spec.add_dependency 'addressable', '>= 2.3.1'
  spec.add_dependency 'referer-parser', '~> 0.3.0'
  spec.add_dependency 'rails', '~> 3.2.0'
end
