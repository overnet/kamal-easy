
lib = File.expand_path("../lib", __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "kamal_easy/version"

Gem::Specification.new do |spec|
  spec.name          = "kamal-easy"
  spec.version       = KamalEasy::VERSION
  spec.authors       = ["Ruslan Vikhor"]
  spec.email         = ["ruslan@overnet.com"]
  spec.summary       = "Unified deployment wrapper for Kamal"
  spec.description   = "Simplifies Kamal deployments with multi-environment support (UAT/Prod) and unified commands for logs and console."
  spec.homepage      = "https://github.com/overnet/kamal-easy"
  spec.license       = "MIT"
  spec.required_ruby_version = ">= 3.3.0"

  spec.files         = Dir.chdir(File.expand_path('..', __FILE__)) do
    `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) || f.match(%r{\.gem$}) }
  end
  spec.bindir        = "bin"
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_dependency "thor", "~> 1.2"
  # Relaxed dependency to avoid conflicts with Rails apps running dotenv 3.x
  spec.add_dependency "dotenv", ">= 2.8", "< 4.0"
end
