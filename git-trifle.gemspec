# encoding: utf-8

$:.unshift File.expand_path('../lib', __FILE__)
require 'git/trifle/version'

Gem::Specification.new do |s|
  s.name          = "git-trifle"
  s.version       = Git::Trifle::VERSION
  s.authors       = ["lacravate"]
  s.email         = ["lacravate@lacravate.fr"]
  s.homepage      = "https://github.com/lacravate/git-trifle"
  s.summary       = "Trifle is a yet another layer around ruby git libs that intends to stick as little as possible to the said underlying lib"
  s.description   = "Trifle is a yet another layer around ruby git libs that intends to stick as little as possible to the said underlying lib"

  s.files         = `git ls-files app lib`.split("\n")
  s.platform      = Gem::Platform::RUBY
  s.require_paths = ['lib']
  s.rubyforge_project = '[none]'

  s.add_dependency "ruby-git-lacravate"
  s.add_development_dependency "rspec"
end
