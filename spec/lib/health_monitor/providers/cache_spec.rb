# frozen_string_literal: true

require 'spec_helper'

RSpec.describe HealthMonitor::Providers::Cache do
  subject(:provider) { described_class.new(request: test_request) }

  describe '#provider_name' do
    it { expect(described_class.provider_name).to eq('Cache') }
  end

  describe '#check!' do
    it 'succesfully checks' do
      expect {
        provider.check!
      }.not_to raise_error
    end

    context 'when failing' do
      before { Providers.stub_cache_failure }

      it 'fails check!' do
        expect {
          provider.check!
        }.to raise_error(HealthMonitor::Providers::CacheException)
      end
    end
  end

  describe '#configurable?' do
    it { expect(described_class).not_to be_configurable }
  end

  describe '#key' do
    it 'is unique per probe to avoid concurrent collisions' do
      expect(provider.instance_variable_get(:@key)).to match(/\Ahealth:0\.0\.0\.0:\h{32}\z/)
    end

    it 'differs between two instances' do
      expect(provider.instance_variable_get(:@key))
        .not_to eq(described_class.new(request: test_request).instance_variable_get(:@key))
    end
  end
end
