require 'spec_helper'

describe HealthMonitor::Providers::Sidekiq do
  describe HealthMonitor::Providers::Sidekiq::Configuration do
    describe 'defaults' do
      it { expect(described_class.new.latency).to eq(HealthMonitor::Providers::Sidekiq::Configuration::DEFAULT_LATENCY_TIMEOUT) }
      it { expect(described_class.new.queue_size).to eq(HealthMonitor::Providers::Sidekiq::Configuration::DEFAULT_QUEUES_SIZE) }
      it { expect(described_class.new.queue_name).to eq(HealthMonitor::Providers::Sidekiq::Configuration::DEFAULT_QUEUE_NAME) }
    end
  end

  subject { described_class.new(request: test_request) }

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
        subject.check!
      }.not_to raise_error
    end

    context 'failing' do
      context 'workers' do
        before do
          Providers.stub_sidekiq_workers_failure
        end

        it 'fails check!' do
          expect {
            subject.check!
          }.to raise_error(HealthMonitor::Providers::SidekiqException)
        end
      end

      context 'processes' do
        before do
          Providers.stub_sidekiq_no_processes_failure
        end

        it 'fails check!' do
          expect {
            subject.check!
          }.to raise_error(HealthMonitor::Providers::SidekiqException)
        end
      end

      context 'latency' do
        before do
          Providers.stub_sidekiq_latency_failure(queue)
        end

        context 'fails' do
          let(:queue) { 'default' }
          it 'fails check!' do
            expect {
              subject.check!
            }.to raise_error(HealthMonitor::Providers::SidekiqException)
          end
        end
        context 'on a different queue' do
          let(:queue) { 'critical' }
          it 'successfully checks' do
            expect {
              subject.check!
            }.not_to raise_error
          end
        end
      end

      context 'queue_size' do
        before do
          Providers.stub_sidekiq_queue_size_failure
        end

        it 'fails check!' do
          expect {
            subject.check!
          }.to raise_error(HealthMonitor::Providers::SidekiqException)
        end
      end

      context 'redis' do
        before do
          Providers.stub_sidekiq_redis_failure
        end

        it 'fails check!' do
          expect {
            subject.check!
          }.to raise_error(HealthMonitor::Providers::SidekiqException)
        end
      end
    end
  end

  describe '#configurable?' do
    it { expect(described_class).to be_configurable }
  end

  describe '#configure' do
    before do
      described_class.configure
    end

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
