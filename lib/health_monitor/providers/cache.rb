# frozen_string_literal: true

module HealthMonitor
  module Providers
    class CacheException < HealthMonitor::Error::ServiceError; end

    class Cache < Base
      def initialize(request: nil)
        super

        @key = ['health', @request.try(:remote_ip)].join(':')
      end

      def check!
        time = Time.now.to_s

        Rails.cache.write(@key, time)
        fetched = Rails.cache.read(@key)

        raise "different values (now: #{time}, fetched: #{fetched})" if fetched != time
      rescue => e
        raise CacheException, e.message
      end
    end
  end
end
