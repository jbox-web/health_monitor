# frozen_string_literal: true

require 'simplecov'

# Start SimpleCov
SimpleCov.start do
  add_filter 'spec/'
end

# Load Rails dummy app
ENV['RAILS_ENV'] = 'test'
require File.expand_path('dummy/config/environment.rb', __dir__)

# Load test gems
require 'rspec/rails'
require 'capybara/rspec'
require 'capybara/rails'
require 'capybara-screenshot/rspec'
require 'database_cleaner'
require 'rediska'
require 'resque'
require 'sidekiq/api'
require 'timecop'

# Load our own config
require_relative 'config_rspec'
require_relative 'config_capybara'

# Requires supporting ruby files with custom matchers and macros, etc, in
# spec/support/ and its subdirectories.
Dir[File.expand_path('support/**/*.rb', __dir__)].each { |f| require f }

def test_request
  if Rails.version >= '5.1'
    ActionController::TestRequest.create(ActionController::Metal)
  elsif Rails.version.start_with?('5')
    ActionController::TestRequest.create
  else
    ActionController::TestRequest.new
  end
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
