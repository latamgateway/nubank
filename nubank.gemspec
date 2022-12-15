# frozen_string_literal: true

require_relative "lib/nubank/version"

Gem::Specification.new do |spec|
  spec.name = "nubank"
  spec.version = Nubank::VERSION
  spec.authors = ["i-tsvetkov"]
  spec.email = ["italo.ext@latamgateway.com"]

  spec.summary = "Nubank API"
  spec.description = "Wrapper for the Nubank API"
  spec.homepage = "https://github.com/latamgateway/nubank"
  spec.required_ruby_version = ">= 2.7.2"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = spec.homepage
  spec.metadata["changelog_uri"] = spec.homepage

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files =
    Dir.chdir(__dir__) do
      `git ls-files -z`.split("\x0")
        .reject do |f|
          (f == __FILE__) ||
            f.match(
              %r{\A(?:(?:bin|test|spec|features)/|\.(?:git|travis|circleci)|appveyor)},
            )
        end
    end

  spec.bindir = "exe"
  spec.executables = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_dependency "curb", "~> 1.0"
  spec.add_dependency "cpf_cnpj", "~> 0.5.0"
  spec.add_dependency "ed25519", "~> 1.3"

  # For more information and examples about making a new gem, check out our
  # guide at: https://bundler.io/guides/creating_gem.html
end
