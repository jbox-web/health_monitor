# frozen_string_literal: true

module HealthMonitor
  class Engine < ::Rails::Engine
    isolate_namespace HealthMonitor

    # Build the default configuration before the host app's initializers run, so
    # they can customize it (e.g. config/initializers/health_monitor.rb).
    config.before_initialize do
      HealthMonitor.configure
    end
  end
end
