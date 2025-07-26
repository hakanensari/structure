# frozen_string_literal: true

$LOAD_PATH.push(File.expand_path("lib", __dir__))
require "structure/version"

Gem::Specification.new do |gem|
  gem.name     = "structure"
  gem.version  = Structure::VERSION
  gem.licenses = ["MIT"]
  gem.summary     = "Structure your data"
  gem.description = "Provides a DSL for generating immutable Ruby Data objects with type coercion and data " \
    "transformation capabilities."
  gem.authors  = ["Hakan Ensari"]
  gem.license  = "MIT"
  gem.files    = Dir.glob("lib/**/*")

  gem.required_ruby_version = ">= 3.2"
  gem.metadata["rubygems_mfa_required"] = "true"
end
