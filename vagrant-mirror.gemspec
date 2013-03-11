# -*- encoding: utf-8 -*-
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'vagrant-mirror/version'

Gem::Specification.new do |gem|
  gem.name          = "vagrant-mirror"
  gem.version       = Vagrant::Mirror::VERSION
  gem.authors       = ["Andrew Coulton"]
  gem.email         = ["andrew@ingenerator.com"]
  gem.description   = 'A Vagrant plugin that mirrors folders between guest and host by monitoring filesystem'
  gem.summary       = gem.description
  gem.homepage      = "https://github.com/ingenerator/vagrant-mirror"

  gem.files         = `git ls-files`.split($/)
  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.require_paths = ["lib"]

  gem.add_dependency 'vagrant'
  gem.add_dependency 'listen'
  gem.add_dependency 'net-sftp', '~>2.0.0'

  gem.add_development_dependency 'rake'
  gem.add_development_dependency 'rspec'
  gem.add_development_dependency 'guard'
  gem.add_development_dependency 'guard-rspec'
end
