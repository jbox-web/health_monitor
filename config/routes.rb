# frozen_string_literal: true

HealthMonitor::Engine.routes.draw do
  get '/(.:format)', to: 'health#check'
end
