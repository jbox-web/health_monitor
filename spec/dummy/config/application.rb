# frozen_string_literal: true

# Load Bundler
require_relative 'boot'

# Load Rails
require 'rails/all'

# Require the gems listed in Gemfile
Bundler.require(*Rails.groups)

module Dummy
  class Application < Rails::Application
    if Rails::VERSION::MAJOR == 7
      config.active_record.legacy_connection_handling = false
    end
  end
end
