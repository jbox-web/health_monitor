# frozen_string_literal: true

require_relative 'lib/health_monitor/version'

Gem::Specification.new do |s|
  s.name        = 'health_monitor'
  s.version     = HealthMonitor::VERSION::STRING
  s.platform    = Gem::Platform::RUBY
  s.authors     = ['Leonid Beder', 'Nicolas Rodriguez']
  s.email       = ['leonid.beder@gmail.com', 'nicoladmin@free.fr']
  s.homepage    = 'https://github.com/jbox-web/health_monitor'
  s.summary     = 'Health monitoring Rails plug-in, which checks various services (db, cache, sidekiq, redis, etc.)'
  s.license     = 'MIT'

  s.required_ruby_version = '>= 2.6.0'

  s.files = `git ls-files`.split("\n")

  s.add_runtime_dependency 'rails', '>= 5.2'
  s.add_runtime_dependency 'zeitwerk'

  s.add_development_dependency 'appraisal'
  s.add_development_dependency 'capybara'
  s.add_development_dependency 'capybara-screenshot'
  s.add_development_dependency 'database_cleaner'
  s.add_development_dependency 'guard-rspec'
  s.add_development_dependency 'pry'
  s.add_development_dependency 'rake'
  s.add_development_dependency 'rediska', '>= 1.0'
  s.add_development_dependency 'resque'
  s.add_development_dependency 'rspec-rails'
  s.add_development_dependency 'rubocop'
  s.add_development_dependency 'sidekiq'
  s.add_development_dependency 'simplecov'
  s.add_development_dependency 'sqlite3', '~> 1.4.0'
  s.add_development_dependency 'timecop'

  if Gem::Version.new(RUBY_VERSION) >= Gem::Version.new("3.1.0")
    s.add_development_dependency 'net-imap'
    s.add_development_dependency 'net-pop'
    s.add_development_dependency 'net-smtp'
  end
end
