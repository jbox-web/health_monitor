# frozen_string_literal: true

require 'spec_helper'

RSpec.describe HealthMonitor::Providers::Sidekiq do
  subject(:provider) { described_class.new(request: test_request) }

  describe HealthMonitor::Providers::Sidekiq::Configuration do
    describe 'defaults' do
      it { expect(described_class.new.latency).to eq(HealthMonitor::Providers::Sidekiq::Configuration::DEFAULT_LATENCY_TIMEOUT) }
      it { expect(described_class.new.queue_size).to eq(HealthMonitor::Providers::Sidekiq::Configuration::DEFAULT_QUEUES_SIZE) }
      it { expect(described_class.new.queue_name).to eq(HealthMonitor::Providers::Sidekiq::Configuration::DEFAULT_QUEUE_NAME) }
    end

    describe '#add_queue_configuration' do
      subject(:configuration) { described_class.new }

      it 'registers an extra queue' do
        expect {
          configuration.add_queue_configuration('critical', latency: 10, queue_size: 20)
        }.to change { configuration.queues['critical'] }.to(latency: 10, queue_size: 20)
      end

      it 'raises when the queue name is blank' do
        expect {
          configuration.add_queue_configuration('')
        }.to raise_error(HealthMonitor::Providers::SidekiqException, 'Queue name is mandatory')
      end
    end
  end

  describe '#provider_name' do
    it { expect(described_class.provider_name).to eq('Sidekiq') }
  end

  describe '#check!' do
    before do
      described_class.configure
      Providers.stub_sidekiq
    end

    it 'succesfully checks' do
      expect {
        provider.check!
      }.not_to raise_error
    end

    context 'when failing' do
      describe 'workers' do
        before { Providers.stub_sidekiq_workers_failure }

        it 'fails check!' do
          expect {
            provider.check!
          }.to raise_error(HealthMonitor::Providers::SidekiqException)
        end
      end

      describe 'processes' do
        before { Providers.stub_sidekiq_no_processes_failure }

        it 'fails check!' do
          expect {
            provider.check!
          }.to raise_error(HealthMonitor::Providers::SidekiqException)
        end
      end

      describe 'latency' do
        before { Providers.stub_sidekiq_latency_failure(queue) }

        context 'when it fails' do
          let(:queue) { 'default' }

          it 'fails check!' do
            expect {
              provider.check!
            }.to raise_error(HealthMonitor::Providers::SidekiqException)
          end
        end

        context 'when on a different queue' do
          let(:queue) { 'critical' }

          it 'successfully checks' do
            expect {
              provider.check!
            }.not_to raise_error
          end
        end
      end

      describe 'queue_size' do
        before { Providers.stub_sidekiq_queue_size_failure }

        it 'fails check!' do
          expect {
            provider.check!
          }.to raise_error(HealthMonitor::Providers::SidekiqException)
        end
      end

      describe 'redis' do
        before { Providers.stub_sidekiq_redis_failure }

        it 'fails check!' do
          expect {
            provider.check!
          }.to raise_error(HealthMonitor::Providers::SidekiqException)
        end
      end
    end

    context 'when Sidekiq exposes redis_info' do
      before { allow(Sidekiq).to receive(:redis_info).and_return('redis_version' => '7') }

      it 'checks through redis_info' do
        expect {
          provider.check!
        }.not_to raise_error

        expect(Sidekiq).to have_received(:redis_info)
      end
    end
  end

  describe '#configurable?' do
    it { expect(described_class).to be_configurable }
  end

  describe '#configure' do
    before { described_class.configure }

    let(:latency) { 123 }

    it 'latency can be configured' do
      expect {
        described_class.configure do |config|
          config.latency = latency
        end
      }.to change { described_class.new.configuration.latency }.to(latency)
    end
  end
end
