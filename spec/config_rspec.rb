# frozen_string_literal: true

RSpec.configure do |config|
  config.include Capybara::DSL
  config.include HealthMonitor::Engine.routes.url_helpers

  config.mock_with :rspec

  config.order = :random
  Kernel.srand config.seed

  # disable monkey patching
  # see: https://relishapp.com/rspec/rspec-core/v/3-8/docs/configuration/zero-monkey-patching-mode
  config.disable_monkey_patching!

  config.before(:suite) do
    DatabaseCleaner.strategy = :transaction
    DatabaseCleaner.clean_with(:truncation)
  end

  config.after(:suite) do
    FileUtils.rm_rf(File.expand_path('test.sqlite3', __dir__))
  end

  config.before do
    DatabaseCleaner.start
  end

  config.after do
    DatabaseCleaner.clean
  end
end
