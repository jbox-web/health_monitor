# frozen_string_literal: true

# Mock out DJ
module Delayed
  class Job # rubocop:disable Lint/EmptyClass
  end
end

class TestClass # rubocop:disable Lint/EmptyClass
end

class CustomProvider < HealthMonitor::Providers::Base
end
