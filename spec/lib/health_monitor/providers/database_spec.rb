# frozen_string_literal: true

require 'spec_helper'

RSpec.describe HealthMonitor::Providers::Database do
  subject(:provider) { described_class.new(request: test_request) }

  describe '#provider_name' do
    it { expect(described_class.provider_name).to eq('Database') }
  end

  describe '#check!' do
    it 'succesfully checks' do
      expect {
        provider.check!
      }.not_to raise_error
    end

    context 'when failing' do
      before { Providers.stub_database_failure }

      it 'fails check!' do
        expect {
          provider.check!
        }.to raise_error(HealthMonitor::Providers::DatabaseException)
      end
    end
  end

  describe '#configurable?' do
    it { expect(described_class).not_to be_configurable }
  end
end
