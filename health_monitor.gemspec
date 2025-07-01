# frozen_string_literal: true

require_relative 'lib/health_monitor/version'

Gem::Specification.new do |s|
  s.name        = 'health_monitor'
  s.version     = HealthMonitor::VERSION::STRING
  s.platform    = Gem::Platform::RUBY
  s.authors     = ['Leonid Beder', 'Nicolas Rodriguez']
  s.email       = ['leonid.beder@gmail.com', 'nico@nicoladmin.fr']
  s.homepage    = 'https://github.com/jbox-web/health_monitor'
  s.summary     = 'Health monitoring Rails plug-in, which checks various services (db, cache, sidekiq, redis, etc.)'
  s.license     = 'MIT'

  s.required_ruby_version = '>= 3.2.0'

  s.files = Dir['README.md', 'CHANGELOG.md', 'LICENSE', 'lib/**/*.rb', 'config/**/*.rb', 'app/**/*.erb']

  s.add_dependency 'rails', '>= 7.0'
  s.add_dependency 'zeitwerk'
end
