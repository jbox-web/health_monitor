# frozen_string_literal: true

require 'spec_helper'

RSpec.describe HealthMonitor do
  before do
    described_class.configuration = HealthMonitor::Configuration.new

    Timecop.freeze(time)
  end

  after do
    Timecop.return
    described_class.configuration = HealthMonitor::Configuration.new
  end

  let(:request) { test_request }

  let(:time) { Time.local(1990) }

  describe '#configure' do
    describe 'providers' do
      it 'configures a single provider' do
        expect {
          described_class.configure(&:redis)
        }.to change { described_class.configuration.providers }
          .to(Set.new([HealthMonitor::Providers::Database, HealthMonitor::Providers::Redis]))
      end

      it 'configures a single provider with custom configuration' do
        expect {
          described_class.configure(&:redis).configure do |redis_config|
            redis_config.url = 'redis://user:pass@example.redis.com:90210/'
          end
        }.to change { described_class.configuration.providers }
          .to(Set.new([HealthMonitor::Providers::Database, HealthMonitor::Providers::Redis]))
      end

      it 'configures a multiple providers' do
        expect {
          described_class.configure do |config|
            config.redis
            config.sidekiq
          end
        }.to change { described_class.configuration.providers }
          .to(Set.new([HealthMonitor::Providers::Database, HealthMonitor::Providers::Redis, HealthMonitor::Providers::Sidekiq]))
      end

      it 'configures multiple providers with custom configuration' do
        expect {
          described_class.configure do |config|
            config.redis
            config.sidekiq.configure do |sidekiq_config|
              sidekiq_config.add_queue_configuration('critical', latency: 10.seconds, queue_size: 20)
            end
          end
        }.to change { described_class.configuration.providers }
          .to(Set.new([HealthMonitor::Providers::Database, HealthMonitor::Providers::Redis, HealthMonitor::Providers::Sidekiq]))
      end

      it 'appends new providers' do
        expect {
          described_class.configure(&:resque)
        }.to change { described_class.configuration.providers }.to(Set.new([HealthMonitor::Providers::Database, HealthMonitor::Providers::Resque]))
      end
    end

    describe 'error_callback' do
      it 'configures' do
        error_callback = proc do
        end

        expect {
          described_class.configure do |config|
            config.error_callback = error_callback
          end
        }.to change { described_class.configuration.error_callback }.to(error_callback)
      end
    end

    describe 'basic_auth_credentials' do
      it 'configures' do
        expected = {
          username: 'username',
          password: 'password',
        }

        expect {
          described_class.configure do |config|
            config.basic_auth_credentials = expected
          end
        }.to change { described_class.configuration.basic_auth_credentials }.to(expected)
      end
    end
  end

  describe '#check' do
    context 'with default providers' do
      it 'succesfully checks' do
        expect(described_class.check(request: request)).to eq(
          results:   [
            {
              name:    'Database',
              message: '',
              status:  'OK',
            },
          ],
          status:    :ok,
          timestamp: time.to_formatted_s(:rfc2822)
        )
      end
    end

    context 'when the providers filter matches no enabled provider' do
      it 'reports an error instead of a vacuous success' do
        expect(described_class.check(request: request, params: { providers: ['redis'] })).to eq(
          results:   [
            {
              name:    'HealthMonitor',
              message: 'No matching providers for the requested filter',
              status:  'ERROR',
            },
          ],
          status:    :service_unavailable,
          timestamp: time.to_formatted_s(:rfc2822)
        )
      end
    end

    context 'when a provider raises a warning' do
      before do
        described_class.configure do |config|
          config.no_database
          config.add_custom_provider(WarningProvider)
        end
      end

      it 'reports a warning and marks the service unavailable' do
        expect(described_class.check(request: request)).to eq(
          results:   [
            {
              name:    'WarningProvider',
              message: 'low on credits',
              status:  'WARNING',
            },
          ],
          status:    :service_unavailable,
          timestamp: time.to_formatted_s(:rfc2822)
        )
      end

      context 'with an error callback' do
        let(:reported) { [] }

        before do
          described_class.configure do |config|
            config.error_callback = ->(e) { reported << e }
          end
        end

        it 'invokes the callback with the warning' do
          described_class.check(request: request)

          expect(reported.map(&:message)).to eq(['low on credits'])
        end
      end
    end

    context 'when a provider raises an unknown state' do
      before do
        described_class.configure do |config|
          config.no_database
          config.add_custom_provider(UnknownProvider)
        end
      end

      it 'reports an unknown status and marks the service unavailable' do
        expect(described_class.check(request: request)).to eq(
          results:   [
            {
              name:    'UnknownProvider',
              message: 'state cannot be determined',
              status:  'UNKNOWN',
            },
          ],
          status:    :service_unavailable,
          timestamp: time.to_formatted_s(:rfc2822)
        )
      end

      context 'with an error callback' do
        let(:reported) { [] }

        before do
          described_class.configure do |config|
            config.error_callback = ->(e) { reported << e }
          end
        end

        it 'invokes the callback with the unknown error' do
          described_class.check(request: request)

          expect(reported.map(&:message)).to eq(['state cannot be determined'])
        end
      end
    end

    context 'with db and redis providers' do
      before do
        described_class.configure do |config|
          config.database
          config.redis.configure
        end
      end

      it 'succesfully checks' do
        expect(described_class.check(request: request)).to eq(
          results:   [
            {
              name:    'Database',
              message: '',
              status:  'OK',
            },
            {
              name:    'Redis',
              message: '',
              status:  'OK',
            },
          ],
          status:    :ok,
          timestamp: time.to_formatted_s(:rfc2822)
        )
      end

      context 'when redis fails' do
        before do
          Providers.stub_redis_failure
        end

        it 'fails check' do
          expect(described_class.check(request: request)).to eq(
            results:   [
              {
                name:    'Database',
                message: '',
                status:  'OK',
              },
              {
                name:    'Redis',
                message: "different values (now: #{time}, fetched: false)",
                status:  'ERROR',
              },
            ],
            status:    :service_unavailable,
            timestamp: time.to_formatted_s(:rfc2822)
          )
        end
      end

      context 'when sidekiq fails' do
        before do
          Providers.stub_sidekiq_workers_failure
        end

        it 'succesfully checks' do
          expect(described_class.check(request: request)).to eq(
            results:   [
              {
                name:    'Database',
                message: '',
                status:  'OK',
              },
              {
                name:    'Redis',
                message: '',
                status:  'OK',
              },
            ],
            status:    :ok,
            timestamp: time.to_formatted_s(:rfc2822)
          )
        end
      end

      context 'when both redis and db fail' do
        before do
          Providers.stub_database_failure
          Providers.stub_redis_failure
        end

        it 'fails check' do
          expect(described_class.check(request: request)).to eq(
            results:   [
              {
                name:    'Database',
                message: 'RuntimeError',
                status:  'ERROR',
              },
              {
                name:    'Redis',
                message: "different values (now: #{time}, fetched: false)",
                status:  'ERROR',
              },
            ],
            status:    :service_unavailable,
            timestamp: time.to_formatted_s(:rfc2822)
          )
        end
      end
    end

    context 'with error callback' do
      test = false

      let(:callback) do
        proc do |e|
          expect(e).to be_present # rubocop:disable RSpec/ExpectInLet
          expect(e).to be_is_a(Exception) # rubocop:disable RSpec/ExpectInLet

          test = true
        end
      end

      before do
        described_class.configure do |config|
          config.database

          config.error_callback = callback
        end

        Providers.stub_database_failure
      end

      it 'calls error_callback' do
        expect(described_class.check(request: request)).to eq(
          results:   [
            {
              name:    'Database',
              message: 'RuntimeError',
              status:  'ERROR',
            },
          ],
          status:    :service_unavailable,
          timestamp: time.to_formatted_s(:rfc2822)
        )

        expect(test).to be_truthy
      end
    end
  end
end
