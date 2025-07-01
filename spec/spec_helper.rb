# frozen_string_literal: true

require 'simplecov'
require 'simplecov_json_formatter'

# Start SimpleCov
SimpleCov.start do
  formatter SimpleCov::Formatter::JSONFormatter
  add_filter 'spec/'
end

# Load Rails dummy app
ENV['RAILS_ENV'] = 'test'
require File.expand_path('dummy/config/environment.rb', __dir__)

# Load test gems
require 'rspec/rails'
require 'sidekiq/api'

# Load our own config
require_relative 'config_rspec'
require_relative 'config_capybara'

# Requires supporting ruby files with custom matchers and macros, etc, in
# spec/support/ and its subdirectories.
Dir[File.expand_path('support/**/*.rb', __dir__)].each { |f| require f }

def test_request
  ActionController::TestRequest.create(ActionController::Metal)
end

def parse_xml(response)
  xml = response.body.gsub('type="symbol"', '')
  Hash.from_xml(xml)['hash']
end

# Mock out DJ
module Delayed
  class Job # rubocop:disable Lint/EmptyClass
  end
end

class TestClass # rubocop:disable Lint/EmptyClass
end

class CustomProvider < HealthMonitor::Providers::Base
end
