RSpec.configure do |config|
  config.include Capybara::DSL
  config.include HealthMonitor::Engine.routes.url_helpers

  config.mock_with :rspec

  config.before(:suite) do
    DatabaseCleaner.strategy = :transaction
    DatabaseCleaner.clean_with(:truncation)
  end

  config.before(:each) do
    DatabaseCleaner.start
  end

  config.after(:each) do
    DatabaseCleaner.clean
  end

  config.after(:suite) do
    FileUtils.rm_rf(File.expand_path('test.sqlite3', __dir__))
  end
end
