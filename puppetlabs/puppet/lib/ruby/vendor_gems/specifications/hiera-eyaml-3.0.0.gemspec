# -*- encoding: utf-8 -*-
# stub: hiera-eyaml 3.0.0 ruby lib

Gem::Specification.new do |s|
  s.name = "hiera-eyaml".freeze
  s.version = "3.0.0"

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib".freeze]
  s.authors = ["Tom Poulton".freeze]
  s.date = "2019-01-17"
  s.description = "Hiera backend for decrypting encrypted yaml properties".freeze
  s.executables = ["eyaml".freeze]
  s.files = ["bin/eyaml".freeze]
  s.homepage = "http://github.com/TomPoulton/hiera-eyaml".freeze
  s.licenses = ["MIT".freeze]
  s.rubygems_version = "2.6.14.3".freeze
  s.summary = "OpenSSL Encryption backend for Hiera".freeze

  s.installed_by_version = "2.6.14.3" if s.respond_to? :installed_by_version

  if s.respond_to? :specification_version then
    s.specification_version = 4

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
      s.add_runtime_dependency(%q<optimist>.freeze, [">= 0"])
      s.add_runtime_dependency(%q<highline>.freeze, ["~> 1.6.19"])
    else
      s.add_dependency(%q<optimist>.freeze, [">= 0"])
      s.add_dependency(%q<highline>.freeze, ["~> 1.6.19"])
    end
  else
    s.add_dependency(%q<optimist>.freeze, [">= 0"])
    s.add_dependency(%q<highline>.freeze, ["~> 1.6.19"])
  end
end
