# frozen_string_literal: true

module HealthMonitor
  class Configuration
    PROVIDERS = %i[cache database redis resque sidekiq].freeze

    attr_accessor :error_callback, :basic_auth_credentials, :environment_variables
    attr_reader :providers

    def initialize
      @providers = Set.new
      database
    end

    def no_database
      @providers.delete(HealthMonitor::Providers::Database)
    end

    PROVIDERS.each do |provider_name|
      klass = provider_name.to_s.titleize.delete(' ')

      class_eval <<-METHOD, __FILE__, __LINE__ + 1
        # frozen_string_literal: true
        def #{provider_name}                                              # def database
          require_relative "providers/#{provider_name}"                   #   require_relative "providers/database"
          add_provider("HealthMonitor::Providers::#{klass}".constantize)  #   add_provider("HealthMonitor::Providers::Database".constantize)
        end                                                               # end
      METHOD
    end

    def add_custom_provider(custom_provider_class)
      unless custom_provider_class < HealthMonitor::Providers::Base
        raise ArgumentError, 'custom provider class must implement HealthMonitor::Providers::Base'
      end

      add_provider(custom_provider_class)
    end

    private

    def add_provider(provider_class)
      @providers << provider_class
      provider_class
    end
  end
end
