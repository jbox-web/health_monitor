# frozen_string_literal: true

module HealthMonitor
  module Providers
    class ResqueException < HealthMonitor::Error::ServiceError; end

    class Resque < Base
      def check!
        ::Resque.info
      rescue Exception => e
        raise ResqueException.new(e.message)
      end
    end
  end
end
