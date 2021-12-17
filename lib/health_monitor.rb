# frozen_string_literal: true

require 'zeitwerk'
loader = Zeitwerk::Loader.for_gem
loader.setup

module HealthMonitor
  require 'health_monitor/engine' if defined?(Rails)

  STATUSES = {
    ok:      'OK',
    warning: 'WARNING',
    error:   'ERROR'
  }.freeze

  extend self

  attr_accessor :configuration

  def configure
    self.configuration ||= Configuration.new

    yield configuration if block_given?
  end

  def check(request: nil, params: {})
    providers = configuration.providers
    if params[:providers].present?
      providers = providers.select { |provider| params[:providers].include?(provider.provider_name.downcase) }
    end

    results = providers.map { |provider| provider_result(provider, request) }

    {
      results: results,
      status: results.any? { |res| res[:status] != STATUSES[:ok] } ? :service_unavailable : :ok,
      timestamp: Time.now.to_formatted_s(:rfc2822)
    }
  end

  private

  def provider_result(provider, request)
    monitor = provider.new(request: request)
    monitor.check!

    {
      name: provider.provider_name,
      message: '',
      status: STATUSES[:ok]
    }
  rescue HealthMonitor::Error::ServiceWarning => e
    configuration.error_callback&.call(e)

    {
      name: provider.provider_name,
      message: e.message,
      status: STATUSES[:warning]
    }
  rescue HealthMonitor::Error, StandardError => e
    configuration.error_callback&.call(e)

    {
      name: provider.provider_name,
      message: e.message,
      status: STATUSES[:error]
    }
  end
end
