# frozen_string_literal: true

module HealthMonitor
  module Error
    class BaseError      < StandardError; end
    class ServiceError   < BaseError; end
    class ServiceWarning < BaseError; end
    class ServiceUnknown < BaseError; end
  end
end
