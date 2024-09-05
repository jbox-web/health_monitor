# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Health Monitor' do
  context 'when check is ok' do
    it 'renders html' do
      visit '/'
      expect(page).to have_css('span', class: 'name', text: 'Database')
      expect(page).to have_css('span', class: 'state', text: 'OK')
    end
  end

  context 'when check failed' do
    before { Providers.stub_database_failure }

    it 'renders html' do
      visit '/'
      expect(page).to have_css('span', class: 'name', text: 'Database')
      expect(page).to have_css('span', class: 'state', text: 'ERROR')
      expect(page).to have_css('div', class: 'message', text: 'RuntimeError')
    end
  end
end
