# frozen_string_literal: true

require_relative "lib/rbs_macros/version"

Gem::Specification.new do |spec|
  spec.name = "rbs_macros"
  spec.version = RbsMacros::VERSION
  spec.authors = ["Wantedly, Inc.", "Masaki Hara"]
  spec.email = ["dev@wantedly.com", "ackie.h.gmai@gmail.com"]

  spec.summary = "RBS meets metaprogramming"
  spec.description = <<~TXT
    Rubyists love metaprogramming.
    This tool bridges between RBS and metaprogramming,
    by allowing you to define a macro,
    which is then used to generate RBS definitions
    based on macro invocations."
  TXT
  spec.homepage = "https://github.com/wantedly/rbs_macros"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 3.2.0"

  spec.metadata["allowed_push_host"] = "https://rubygems.org"
  spec.metadata["rubygems_mfa_required"] = "true"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "https://github.com/wantedly/rbs_macros"
  spec.metadata["changelog_uri"] = "https://github.com/wantedly/rbs_macros/tree/master/CHANGELOG.md"

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files = Dir.chdir(__dir__) do
    `git ls-files -z`.split("\x0").reject do |f|
      (File.expand_path(f) == __FILE__) ||
        f.start_with?("bin/", "test/", "spec/", "features/", ".git", ".circleci", "appveyor", "Gemfile")
    end
  end
  spec.bindir = "exe"
  spec.executables = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  # Uncomment to register a new dependency of your gem
  spec.add_dependency "fileutils", "~> 1.7"
  spec.add_dependency "forwardable", "~> 1.3"
  spec.add_dependency "prism", "~> 0.24.0"
  spec.add_dependency "rbs", "~> 3.4"

  # For more information and examples about making a new gem, check out our
  # guide at: https://bundler.io/guides/creating_gem.html
end
