# -*- encoding: utf-8 -*-
# stub: stomp 1.4.4 ruby lib

Gem::Specification.new do |s|
  s.name = "stomp".freeze
  s.version = "1.4.4"

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib".freeze]
  s.authors = ["Brian McCallister".freeze, "Marius Mathiesen".freeze, "Thiago Morello".freeze, "Guy M. Allard".freeze]
  s.date = "2017-06-11"
  s.description = "Ruby client for the Stomp messaging protocol.  Note that this gem is no longer supported on rubyforge.".freeze
  s.email = ["brianm@apache.org".freeze, "marius@stones.com".freeze, "morellon@gmail.com".freeze, "allard.guy.m@gmail.com".freeze]
  s.executables = ["catstomp".freeze, "stompcat".freeze]
  s.extra_rdoc_files = ["LICENSE".freeze, "README.md".freeze]
  s.files = ["LICENSE".freeze, "README.md".freeze, "bin/catstomp".freeze, "bin/stompcat".freeze]
  s.homepage = "https://github.com/stompgem/stomp".freeze
  s.licenses = ["Apache-2.0".freeze]
  s.rubygems_version = "2.6.14.3".freeze
  s.summary = "Ruby client for the Stomp messaging protocol".freeze

  s.installed_by_version = "2.6.14.3" if s.respond_to? :installed_by_version

  if s.respond_to? :specification_version then
    s.specification_version = 4

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
      s.add_development_dependency(%q<rspec>.freeze, [">= 2.14.1", "~> 2.14"])
    else
      s.add_dependency(%q<rspec>.freeze, [">= 2.14.1", "~> 2.14"])
    end
  else
    s.add_dependency(%q<rspec>.freeze, [">= 2.14.1", "~> 2.14"])
  end
end
