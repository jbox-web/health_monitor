# frozen_string_literal: true

module HealthMonitor
  # Exception hierarchy raised by providers to signal a failed check. Which
  # class is raised drives the status HealthMonitor.provider_result assigns:
  #   - ServiceWarning => WARNING (degraded but still serving)
  #   - ServiceUnknown => UNKNOWN (state could not be determined)
  #   - any other exception (ServiceError, or a plain StandardError) => ERROR
  # Any non-OK status makes the aggregate check return 503 Service Unavailable.
  module Error
    class BaseError      < StandardError; end
    class ServiceError   < BaseError; end
    class ServiceWarning < BaseError; end
    class ServiceUnknown < BaseError; end
  end
end
