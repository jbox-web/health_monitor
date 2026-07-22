# frozen_string_literal: true

require 'securerandom'

module HealthMonitor
  module Providers
    class CacheException < HealthMonitor::Error::ServiceError; end

    class Cache < Base
      def initialize(request: nil)
        super

        # The random suffix makes the probe key unique per instance so two
        # concurrent checks (e.g. several pollers behind the same IP) can never
        # overwrite each other's value and trigger a false mismatch.
        @key = ['health', @request.try(:remote_ip), SecureRandom.hex].join(':')
      end

      def check!
        time = Time.now.to_s

        Rails.cache.write(@key, time)
        fetched = Rails.cache.read(@key)

        raise "different values (now: #{time}, fetched: #{fetched})" if fetched != time
      rescue => e
        raise CacheException, e.message
      ensure
        # Per-probe keys must be cleaned up, otherwise the unique keys would
        # accumulate unbounded in the cache store.
        Rails.cache.delete(@key)
      end
    end
  end
end
