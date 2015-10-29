# Generated by jeweler
# DO NOT EDIT THIS FILE DIRECTLY
# Instead, edit Jeweler::Tasks in Rakefile, and run 'rake gemspec'
# -*- encoding: utf-8 -*-
# stub: chantier 2.1.0 ruby lib

Gem::Specification.new do |s|
  s.name = "chantier"
  s.version = "2.1.0"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib"]
  s.authors = ["Julik Tarkhanov"]
  s.date = "2015-10-29"
  s.description = " Process your jobs in parallel with a simple table of processes or threads "
  s.email = "me@julik.nl"
  s.extra_rdoc_files = [
    "LICENSE.txt",
    "README.md"
  ]
  s.files = [
    ".document",
    ".rspec",
    ".travis.yml",
    "Gemfile",
    "LICENSE.txt",
    "README.md",
    "Rakefile",
    "chantier.gemspec",
    "lib/chantier.rb",
    "lib/failure_policies.rb",
    "lib/process_pool.rb",
    "lib/process_pool_with_kill.rb",
    "lib/thread_pool.rb",
    "spec/failure_policy_by_percentage_spec.rb",
    "spec/failure_policy_counter_spec.rb",
    "spec/failure_policy_mutex_wrapper_spec.rb",
    "spec/failure_policy_spec.rb",
    "spec/failure_policy_within_interval_spec.rb",
    "spec/process_pool_spec.rb",
    "spec/process_pool_with_kill_spec.rb",
    "spec/spec_helper.rb",
    "spec/thread_pool_spec.rb"
  ]
  s.homepage = "http://github.com/julik/chantier"
  s.licenses = ["MIT"]
  s.rubygems_version = "2.2.2"
  s.summary = "Dead-simple worker table based multiprocessing/multithreading"

  if s.respond_to? :specification_version then
    s.specification_version = 4

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
      s.add_development_dependency(%q<rspec>, ["~> 2.9"])
      s.add_development_dependency(%q<rdoc>, ["~> 3.12"])
      s.add_development_dependency(%q<bundler>, ["~> 1.0"])
      s.add_development_dependency(%q<jeweler>, ["~> 2.0.1"])
      s.add_development_dependency(%q<simplecov>, [">= 0"])
    else
      s.add_dependency(%q<rspec>, ["~> 2.9"])
      s.add_dependency(%q<rdoc>, ["~> 3.12"])
      s.add_dependency(%q<bundler>, ["~> 1.0"])
      s.add_dependency(%q<jeweler>, ["~> 2.0.1"])
      s.add_dependency(%q<simplecov>, [">= 0"])
    end
  else
    s.add_dependency(%q<rspec>, ["~> 2.9"])
    s.add_dependency(%q<rdoc>, ["~> 3.12"])
    s.add_dependency(%q<bundler>, ["~> 1.0"])
    s.add_dependency(%q<jeweler>, ["~> 2.0.1"])
    s.add_dependency(%q<simplecov>, [">= 0"])
  end
end

