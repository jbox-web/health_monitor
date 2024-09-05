# frozen_string_literal: true

module HealthMonitor
  module Providers
    class DatabaseException < HealthMonitor::Error::ServiceError; end

    class Database < Base
      def check!
        # Check connection to the DB:
        ActiveRecord::Migrator.current_version
      rescue => e
        raise DatabaseException, e.message
      end
    end
  end
end
