module HealthMonitor
  class BaseError < StandardError; end
  class Error     < BaseError; end
  class Warning   < BaseError; end
end
