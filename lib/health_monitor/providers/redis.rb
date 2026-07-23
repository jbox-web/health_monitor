# frozen_string_literal: true

require 'securerandom'

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
        # We only own (and may close) the connection when we created it here;
        # an injected connection/pool belongs to the caller.
        @owns_connection = configuration.connection.nil?
        # Random suffix => unique probe key per instance, so concurrent checks
        # never overwrite each other's value (false mismatch).
        @key = ['health', @request.try(:remote_ip), SecureRandom.hex].join(':')
      end

      def check!
        check_values!
        check_max_used_memory!
      rescue => e
        raise RedisException, e.message
      ensure
        redis_cleanup
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

      # Cleanup runs in an ensure block: swallow its own failures so a broken
      # connection during teardown cannot mask the real check error.
      def redis_cleanup
        redis_del(@key)
      rescue
        nil
      ensure
        redis_close
      end

      def check_values!
        time = Time.now

        redis_set(@key, time)
        fetched = redis_get(@key)

        raise "different values (now: #{time}, fetched: #{fetched})" if fetched != time.to_s
      end

      def redis_set(key, value)
        if connection_pool?
          @redis.with { |con| con.set(key, value) }
        else
          @redis.set(key, value)
        end
      end

      def redis_get(key)
        if connection_pool?
          @redis.with { |con| con.get(key) }
        else
          @redis.get(key)
        end
      end

      def redis_del(key)
        if connection_pool?
          @redis.with { |con| con.del(key) }
        else
          @redis.del(key)
        end
      end

      # We only reach here when @owns_connection is true, which happens only
      # when no connection was injected: @redis is then a plain ::Redis built in
      # redis_connection, never a ConnectionPool. So no pool branch is needed.
      def redis_close
        return unless @owns_connection

        @redis.close
      rescue
        nil
      end

      def redis_info
        if connection_pool?
          @redis.with(&:info)
        else
          @redis.info
        end
      end

      def connection_pool?
        @redis.is_a?(ConnectionPool)
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
        bytes_to_megabytes(redis_info['used_memory'])
      end
    end
  end
end
