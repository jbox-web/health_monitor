# frozen_string_literal: true

require 'spec_helper'

RSpec.describe HealthMonitor::Configuration do
  subject(:configuration) { described_class.new }

  let(:default_configuration) { Set.new([HealthMonitor::Providers::Database]) }

  describe 'defaults' do
    it { expect(configuration.providers).to eq(default_configuration) }
    it { expect(configuration.error_callback).to be_nil }
    it { expect(configuration.basic_auth_credentials).to be_nil }
  end

  describe 'providers' do
    HealthMonitor::Configuration::PROVIDERS.each do |provider_name|
      before do
        configuration.instance_variable_set(:@providers, Set.new)

        stub_const("HealthMonitor::Providers::#{provider_name.to_s.titleize.delete(' ')}", Class.new)
      end

      it "responds to #{provider_name}" do
        expect(configuration).to respond_to(provider_name)
      end

      it "configures #{provider_name}" do
        expect {
          configuration.send(provider_name)
        }.to change(configuration, :providers).to(Set.new(["HealthMonitor::Providers::#{provider_name.to_s.titleize.delete(' ')}".constantize]))
      end

      it "returns #{provider_name}'s class" do
        expect(configuration.send(provider_name)).to eq("HealthMonitor::Providers::#{provider_name.to_s.titleize.delete(' ')}".constantize)
      end
    end
  end

  describe '#add_custom_provider' do
    before do
      configuration.instance_variable_set(:@providers, Set.new)
    end

    context 'when it inherits' do
      it 'accepts' do
        expect {
          configuration.add_custom_provider(CustomProvider)
        }.to change(configuration, :providers).to(Set.new([CustomProvider]))
      end

      it 'returns CustomProvider class' do
        expect(configuration.add_custom_provider(CustomProvider)).to eq(CustomProvider)
      end
    end

    context 'when it does not inherit' do
      it 'does not accept' do
        expect {
          configuration.add_custom_provider(TestClass)
        }.to raise_error(ArgumentError)
      end
    end
  end

  describe '#no_database' do
    it 'removes the default database check' do
      expect {
        configuration.no_database
      }.to change(configuration, :providers).from(default_configuration).to(Set.new)
    end
  end
end
