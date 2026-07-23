# frozen_string_literal: true

# require external dependencies
require 'zeitwerk'

# load zeitwerk
Zeitwerk::Loader.for_gem.tap do |loader| # rubocop:disable Style/SymbolProc
  loader.setup
end

module HealthMonitor
  require_relative 'health_monitor/engine' if defined?(Rails)

  STATUSES = {
    ok:      'OK',
    warning: 'WARNING',
    unknown: 'UNKNOWN',
    error:   'ERROR',
  }.freeze

  extend self

  attr_accessor :configuration

  def configure
    self.configuration ||= Configuration.new

    yield configuration if block_given?
  end

  def check(request: nil, params: {})
    results = run_checks(request, params)

    {
      results:   results,
      status:    results.any? { |res| res[:status] != STATUSES[:ok] } ? :service_unavailable : :ok,
      timestamp: Time.now.to_formatted_s(:rfc2822),
    }
  end

  private

  def run_checks(request, params) # rubocop:disable Metrics/AbcSize
    providers = configuration.providers
    if params[:providers].present?
      providers = providers.select { |provider| params[:providers].include?(provider.provider_name.downcase) }
    end

    results = providers.map { |provider| provider_result(provider, request) }

    # A providers filter that matches no enabled provider must not report a
    # vacuous success: an empty result set would otherwise aggregate to :ok and
    # let a misconfigured monitor believe the service is healthy while nothing
    # was actually checked.
    results << no_matching_providers_result if params[:providers].present? && results.empty?

    results
  end

  def no_matching_providers_result
    {
      name:    'HealthMonitor',
      message: 'No matching providers for the requested filter',
      status:  STATUSES[:error],
    }
  end

  def provider_result(provider, request)
    monitor = provider.new(request: request)
    monitor.check!

    result(provider, '', STATUSES[:ok])
  rescue HealthMonitor::Error::ServiceWarning => e
    failure(provider, e, STATUSES[:warning])
  rescue HealthMonitor::Error::ServiceUnknown => e
    failure(provider, e, STATUSES[:unknown])
  rescue HealthMonitor::Error, StandardError => e
    failure(provider, e, STATUSES[:error])
  end

  # Notify the configured error callback, then build the failed-check result.
  def failure(provider, error, status)
    configuration.error_callback&.call(error)

    result(provider, error.message, status)
  end

  def result(provider, message, status)
    {
      name:    provider.provider_name,
      message: message,
      status:  status,
    }
  end
end
