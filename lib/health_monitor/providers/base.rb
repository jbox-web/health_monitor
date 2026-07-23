# frozen_string_literal: true

module HealthMonitor
  module Providers
    # Base class and contract for every health provider.
    #
    # A provider subclasses Base and implements #check!. A check is considered
    # *failed* when #check! raises: raising Error::ServiceWarning yields a
    # WARNING status, any other exception yields ERROR, and returning normally
    # yields OK (see HealthMonitor.provider_result).
    #
    # Optional per-provider configuration: define a nested Configuration class
    # and override the private class method .configuration_class to return it.
    # .configure then builds a single class-level configuration shared by every
    # instance (exposed as #configuration). Providers whose configuration_class
    # is nil are non-configurable.
    class Base
      attr_reader   :request
      attr_accessor :configuration

      def initialize(request: nil)
        @request = request

        return unless self.class.configurable?

        self.configuration = self.class.instance_variable_get(:@global_configuration)
      end

      class << self
        # Name used in the result payload and matched (case-insensitively,
        # downcased) by the ?providers[]= filter. Defaults to the demodulized
        # class name; override to expose a custom label.
        def provider_name
          @provider_name ||= name.demodulize
        end

        def configure
          return unless configurable?

          @global_configuration = configuration_class.new

          yield @global_configuration if block_given?
        end

        def configurable?
          configuration_class
        end

        # Overridden by configurable providers to return their Configuration
        # class; nil (the default) marks the provider as non-configurable.
        def configuration_class; end
      end

      # @abstract
      def check!
        raise NotImplementedError
      end
    end
  end
end
