# -*- encoding: utf-8 -*-
# stub: text 1.3.1 ruby lib

Gem::Specification.new do |s|
  s.name = "text".freeze
  s.version = "1.3.1"

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib".freeze]
  s.authors = ["Paul Battley".freeze, "Michael Neumann".freeze, "Tim Fletcher".freeze]
  s.date = "2015-04-13"
  s.description = "A collection of text algorithms: Levenshtein, Soundex, Metaphone, Double Metaphone, Porter Stemming".freeze
  s.email = "pbattley@gmail.com".freeze
  s.extra_rdoc_files = ["README.rdoc".freeze, "COPYING.txt".freeze]
  s.files = ["COPYING.txt".freeze, "README.rdoc".freeze]
  s.homepage = "http://github.com/threedaymonk/text".freeze
  s.licenses = ["MIT".freeze]
  s.rubyforge_project = "text".freeze
  s.rubygems_version = "2.6.14.3".freeze
  s.summary = "A collection of text algorithms".freeze

  s.installed_by_version = "2.6.14.3" if s.respond_to? :installed_by_version

  if s.respond_to? :specification_version then
    s.specification_version = 4

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
      s.add_development_dependency(%q<rake>.freeze, ["~> 10.0"])
    else
      s.add_dependency(%q<rake>.freeze, ["~> 10.0"])
    end
  else
    s.add_dependency(%q<rake>.freeze, ["~> 10.0"])
  end
end
