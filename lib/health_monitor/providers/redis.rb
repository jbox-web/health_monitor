# frozen_string_literal: true

module HealthMonitor
  module Providers
    class RedisException < HealthMonitor::Error::ServiceError; end

    class Redis < Base
      class Configuration
        DEFAULT_URL = 'redis://localhost:6379'

        attr_accessor :url, :connection, :max_used_memory

        def initialize
          @url = DEFAULT_URL
        end
      end

      class << self
        private

        def configuration_class
          ::HealthMonitor::Providers::Redis::Configuration
        end
      end

      def initialize(request: nil)
        super

        @redis = redis_connection
        @key = ['health', @request.try(:remote_ip)].join(':')
      end

      def check!
        check_values!
        check_max_used_memory!
      rescue => e
        raise RedisException, e.message
      ensure
        @redis.close
      end

      private

      def redis_connection
        if configuration.connection
          configuration.connection
        elsif configuration.url
          ::Redis.new(url: configuration.url)
        else
          ::Redis.new
        end
      end

      def check_values!
        time = Time.now

        @redis.set(@key, time)
        fetched = @redis.get(@key)

        raise "different values (now: #{time}, fetched: #{fetched})" if fetched != time.to_s
      end

      def check_max_used_memory!
        return unless configuration.max_used_memory
        return if used_memory_mb <= configuration.max_used_memory

        raise "#{used_memory_mb}Mb memory using is higher than #{configuration.max_used_memory}Mb maximum expected"
      end

      def bytes_to_megabytes(bytes)
        (bytes.to_f / 1024 / 1024).round
      end

      def used_memory_mb
        bytes_to_megabytes(@redis.info['used_memory'])
      end
    end
  end
end
