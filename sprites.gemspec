# frozen_string_literal: true

require_relative "lib/sprites/version"

Gem::Specification.new do |spec|
  spec.name = "sprites-ruby"
  spec.version = Sprites::VERSION
  spec.authors = ["Ara Hacopian"]
  spec.email = ["ara@hacopian.de"]

  spec.summary = "Ruby client for the Sprites API"
  spec.description = "Ruby client for the Sprites API - stateful sandbox environments"
  spec.homepage = "https://github.com/ahacop/sprites-ruby"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 3.2.0"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = spec.homepage
  spec.metadata["changelog_uri"] = "#{spec.homepage}/blob/main/CHANGELOG.md"

  spec.files = Dir["lib/**/*", "LICENSE", "README.md", "CHANGELOG.md"]
  spec.require_paths = ["lib"]

  spec.add_dependency "faraday", "~> 2.0"
end
