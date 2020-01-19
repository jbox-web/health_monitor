# frozen_string_literal: true

module HealthMonitor
  class HealthController < ActionController::Base
    protect_from_forgery with: :exception
    before_action :authenticate_with_basic_auth

    def check
      @statuses = statuses

      respond_to do |format|
        format.html
        format.json do
          render json: statuses.to_json, status: statuses[:status]
        end
        format.xml do
          render xml: statuses.to_xml, status: statuses[:status]
        end
      end
    end

    private

    def statuses
      res = HealthMonitor.check(request: request, params: providers_params)
      res.merge(env_vars)
    end

    def env_vars
      v = HealthMonitor.configuration.environment_variables || {}
      v.empty? ? {} : { environment_variables: v }
    end

    def authenticate_with_basic_auth
      return true unless HealthMonitor.configuration.basic_auth_credentials

      credentials = HealthMonitor.configuration.basic_auth_credentials
      authenticate_or_request_with_http_basic do |name, password|
        name == credentials[:username] && password == credentials[:password]
      end
    end

    def providers_params
      params.permit(:format, providers: [])
    end
  end
end
