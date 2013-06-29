# -*- encoding: utf-8 -*-
lib = File.expand_path('../lib/', __FILE__)
$:.unshift lib unless $:.include?(lib)
 
require 'db_tools/version'
 
Gem::Specification.new do |spec|
  spec.name        = "dbtools"
  spec.version     = DbTools::VERSION
  spec.platform    = Gem::Platform::RUBY
  spec.authors     = ["Michael Berkovich"]
  spec.email       = ["theiceberk@gmail.com"]
  spec.homepage    = "https://github.com/berk/db_tools"
  spec.summary     = "Tools for running simple DB tasks"
  spec.description = "Set of handy utilities for managing database, etc..."
 
  spec.files        = Dir.glob("{bin,lib}/**/*") + %w(LICENSE README.rdoc)
  spec.executables  = spec.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  spec.test_files   = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_path = ['lib', 'lib/db_tools']

  spec.add_dependency 'thor', '~> 0.16.0'
  spec.add_dependency 'activerecord'
  spec.add_dependency 'sinatra'
end
