# -*- encoding: utf-8 -*-
$LOAD_PATH.unshift 'lib'
require "mgframework/version"

Gem::Specification.new do |s|
  s.name        = "mgframework"
  s.version     = MGF::Version
  s.author      = "MOZGIII"
  s.homepage    = "http://github.com/MOZGIII/MGFramework"
  s.summary     = "M is Games Framework."
  s.description = "MGFramework is a simple game framework."
  
  s.files        = `git ls-files`.split("\n")
  s.executables  = `git ls-files`.split("\n").select{|f| f =~ /^bin/}
  s.require_path = "lib"
  
  s.add_dependency('eventmachine', '>= 1.0.0.beta.3')
  s.add_dependency('em-websocket', '>= 0.3.0')
  
  s.rdoc_options = ["--title", "MGFramework", "--main", "README.md", "-x", "lib/mgframework/version"]
end