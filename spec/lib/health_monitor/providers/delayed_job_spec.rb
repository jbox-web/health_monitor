# frozen_string_literal: true

require 'spec_helper'

RSpec.describe HealthMonitor::Providers::DelayedJob do
  subject(:provider) { described_class.new(request: test_request) }

  describe HealthMonitor::Providers::DelayedJob::Configuration do
    describe 'defaults' do
      it { expect(described_class.new.queue_size).to eq(HealthMonitor::Providers::DelayedJob::Configuration::DEFAULT_QUEUES_SIZE) }
    end
  end

  describe '#provider_name' do
    it { expect(described_class.provider_name).to eq('DelayedJob') }
  end

  describe '#check!' do
    before { described_class.configure }

    context 'when success' do
      before { Providers.stub_delayed_job }

      it 'succesfully checks' do
        expect {
          provider.check!
        }.not_to raise_error
      end
    end

    context 'when failing' do
      before { Providers.stub_delayed_job_failure }

      it 'fails check!' do
        expect {
          provider.check!
        }.to raise_error(HealthMonitor::Providers::DelayedJobException)
      end
    end
  end

  describe '#configurable?' do
    it { expect(described_class).to be_configurable }
  end

  describe '#configure' do
    before { described_class.configure }

    let(:queue_size) { 123 }

    it 'queue_size can be configured' do
      expect {
        described_class.configure do |config|
          config.queue_size = queue_size
        end
      }.to change { described_class.new.configuration.queue_size }.to(queue_size)
    end
  end
end
