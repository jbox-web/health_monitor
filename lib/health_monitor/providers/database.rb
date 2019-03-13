# frozen_string_literal: true

module HealthMonitor
  module Providers
    class DatabaseException < HealthMonitor::Error::ServiceError; end

    class Database < Base
      def check!
        # Check connection to the DB:
        ActiveRecord::Migrator.current_version
      rescue Exception => e
        raise DatabaseException.new(e.message)
      end
    end
  end
end
