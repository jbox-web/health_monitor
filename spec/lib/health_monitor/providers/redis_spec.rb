# frozen_string_literal: true

require 'spec_helper'

RSpec.describe HealthMonitor::Providers::Redis do
  subject(:provider) { described_class.new(request: test_request) }

  describe HealthMonitor::Providers::Redis::Configuration do
    describe 'defaults' do
      it { expect(described_class.new.url).to eq(HealthMonitor::Providers::Redis::Configuration::DEFAULT_URL) }
    end
  end

  describe '#provider_name' do
    it { expect(described_class.provider_name).to eq('Redis') }
  end

  describe '#check!' do
    describe 'values' do
      context 'when success' do
        before { described_class.configure }

        it 'succesfully checks' do
          expect {
            provider.check!
          }.not_to raise_error
        end
      end

      context 'when failing' do
        before do
          described_class.configure
          Providers.stub_redis_failure
        end

        it 'fails check!' do
          expect {
            provider.check!
          }.to raise_error(HealthMonitor::Providers::RedisException)
        end
      end
    end

    describe 'max_used_memory' do
      context 'when success' do
        before { described_class.configure }

        it 'succesfully checks' do
          expect {
            provider.check!
          }.not_to raise_error
        end
      end

      context 'when failing' do
        before do
          described_class.configure do |config|
            config.max_used_memory = 100
          end

          Providers.stub_redis_max_user_memory_failure
        end

        it 'fails check!' do
          expect {
            provider.check!
          }.to raise_error(HealthMonitor::Providers::RedisException, '954Mb memory using is higher than 100Mb maximum expected')
        end
      end
    end
  end

  describe '#configurable?' do
    it { expect(described_class).to be_configurable }
  end

  describe '#configure' do
    before { described_class.configure }

    describe '#connection' do
      let(:redis_connection) { double :redis_connection, close: true } # rubocop:disable RSpec/VerifiedDoubles

      it 'connection could be configured' do
        expect {
          described_class.configure do |config|
            config.connection = redis_connection
          end
        }.to change { described_class.new.configuration.connection }.to(redis_connection)
      end

      it 'connection configuration is persistent accross instnaces' do
        expect {
          described_class.configure do |config|
            config.connection = redis_connection
          end

          described_class.new
        }.to change { described_class.new.configuration.connection }.to(redis_connection)
      end
    end

    describe '#url' do
      let(:url) { 'redis://user:password@fake.redis.com:91210/' }

      it 'url can be configured' do
        expect {
          described_class.configure do |config|
            config.url = url
          end
        }.to change { described_class.new.configuration.url }.to(url)
      end

      it 'url configuration is persistent' do
        expect {
          described_class.configure do |config|
            config.url = url
          end

          HealthMonitor::Providers::Sidekiq.configure do |config|
            config.latency = 123
          end
        }.to change { described_class.new.configuration.url }.to(url)
      end

      it 'url configuration is persistent accross instnaces' do
        expect {
          described_class.configure do |config|
            config.url = url
          end

          described_class.new
        }.to change { described_class.new.configuration.url }.to(url)
      end
    end

    describe '#max_used_memory' do
      let(:max_used_memory) { 10 }

      it 'max_used_memory can be configured' do
        expect {
          described_class.configure do |config|
            config.max_used_memory = max_used_memory
          end
        }.to change { described_class.new.configuration.max_used_memory }.to(max_used_memory)
      end

      it 'max_used_memory configuration is persistent' do
        expect {
          described_class.configure do |config|
            config.max_used_memory = max_used_memory
          end

          HealthMonitor::Providers::Sidekiq.configure do |config|
            config.latency = 123
          end
        }.to change { described_class.new.configuration.max_used_memory }.to(max_used_memory)
      end

      it 'max_used_memory configuration is persistent accross instnaces' do
        expect {
          described_class.configure do |config|
            config.max_used_memory = max_used_memory
          end

          described_class.new
        }.to change { described_class.new.configuration.max_used_memory }.to(max_used_memory)
      end
    end
  end

  describe '#key' do
    before { described_class.configure }

    it 'is unique per probe to avoid concurrent collisions' do
      expect(provider.instance_variable_get(:@key)).to match(/\Ahealth:0\.0\.0\.0:\h{32}\z/)
    end

    it 'differs between two instances' do
      expect(provider.instance_variable_get(:@key))
        .not_to eq(described_class.new(request: test_request).instance_variable_get(:@key))
    end
  end

  describe 'connection ownership' do
    let(:store) { {} }
    let(:connection) do
      instance_double(Redis).tap do |conn|
        allow(conn).to receive(:set) { |key, value| store[key] = value.to_s }
        allow(conn).to receive(:get) { |key| store[key] }
        allow(conn).to receive(:del) { |key| store.delete(key) }
        allow(conn).to receive(:close)
      end
    end

    before do
      described_class.configure do |config|
        config.connection = connection
      end
    end

    it 'does not close a connection it does not own' do
      provider.check!

      expect(connection).not_to have_received(:close)
    end

    context 'when cleanup fails during teardown' do
      before { allow(connection).to receive(:del).and_raise('boom') }

      it 'swallows the teardown error and does not mask a successful check' do
        expect {
          provider.check!
        }.not_to raise_error
      end
    end
  end

  describe 'when closing an owned connection fails' do
    before do
      described_class.configure
      allow_any_instance_of(Redis).to receive(:close).and_raise('boom')
    end

    it 'swallows the close error' do
      expect {
        provider.check!
      }.not_to raise_error
    end
  end

  describe 'when neither connection nor url is configured' do
    before do
      described_class.configure do |config|
        config.connection = nil
        config.url = nil
      end
    end

    it 'builds a default Redis connection and checks successfully' do
      expect {
        provider.check!
      }.not_to raise_error
    end
  end

  describe 'with a ConnectionPool' do
    let(:store) { {} }
    let(:pooled_connection) do
      instance_double(Redis).tap do |conn|
        allow(conn).to receive(:set) { |key, value| store[key] = value.to_s }
        allow(conn).to receive(:get) { |key| store[key] }
        allow(conn).to receive(:del) { |key| store.delete(key) }
        allow(conn).to receive(:close)
        allow(conn).to receive(:info).and_return('used_memory' => '1024')
      end
    end
    let(:pool) { ConnectionPool.new(size: 1, timeout: 1) { pooled_connection } }

    before do
      described_class.configure do |config|
        config.connection = pool
        config.max_used_memory = 100
      end
    end

    it 'routes every call through the pool and checks successfully' do
      expect {
        provider.check!
      }.not_to raise_error

      expect(pooled_connection).to have_received(:set)
      expect(pooled_connection).to have_received(:get)
      expect(pooled_connection).to have_received(:info)
    end
  end
end
