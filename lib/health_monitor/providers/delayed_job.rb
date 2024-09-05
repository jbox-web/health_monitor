# frozen_string_literal: true

module HealthMonitor
  module Providers
    class DelayedJobException < HealthMonitor::Error::ServiceError; end

    class DelayedJob < Base
      class Configuration
        DEFAULT_QUEUES_SIZE = 100

        attr_accessor :queue_size

        def initialize
          @queue_size = DEFAULT_QUEUES_SIZE
        end
      end

      def initialize(request: nil)
        super

        @job_class = ::Delayed::Job
      end

      def check!
        check_queue_size!
      rescue => e
        raise DelayedJobException, e.message
      end

      private

      class << self
        private

        def configuration_class
          ::HealthMonitor::Providers::DelayedJob::Configuration
        end
      end

      def check_queue_size!
        size = @job_class.count

        return unless size > configuration.queue_size

        raise "queue size #{size} is greater than #{configuration.queue_size}"
      end
    end
  end
end
