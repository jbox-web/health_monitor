# frozen_string_literal: true

module HealthMonitor
  class Engine < ::Rails::Engine
    isolate_namespace HealthMonitor

    config.before_initialize do
      HealthMonitor.configure
    end
  end
end
