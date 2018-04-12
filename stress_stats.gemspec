
lib = File.expand_path("../lib", __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "stress_stats/version"

Gem::Specification.new do |spec|
  spec.name          = "stress_stats"
  spec.version       = StressStats::VERSION
  spec.authors       = ["Lucas Blotta"]
  spec.email         = ["l_blotta@hotmail.com"]

  spec.summary       = %q{Remote System Statistics Gathering}
  spec.description   = %q{Gather sysstats statistics from a remote host for the duration of a command}
  spec.homepage      = "https://github.com/blotta/stress_stats"
  spec.license       = "MIT"

  # Prevent pushing this gem to RubyGems.org. To allow pushes either set the 'allowed_push_host'
  # to allow pushing to a single host or delete this section to allow pushing to any host.
  if spec.respond_to?(:metadata)
    spec.metadata["allowed_push_host"] = "TODO: Set to 'http://mygemserver.com'"
  else
    raise "RubyGems 2.0 or newer is required to protect against " \
      "public gem pushes."
  end

  spec.files         = `git ls-files -z`.split("\x0").reject do |f|
    f.match(%r{^(test|spec|features)/})
  end
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.16"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "rspec", "~> 3.0"

  spec.add_dependency "net-ssh", "~> 4.2"
  spec.add_dependency "colorize", "~> 0.8"

end
