require 'spec_helper'

describe 'Health Monitor' do
  context 'when check is ok' do
    it 'renders html' do
      visit '/'
      expect(page).to have_css('span', class: 'name', text: 'Database')
      expect(page).to have_css('span', class: 'state', text: 'OK')
    end
  end

  context 'when check failed' do
    before do
      Providers.stub_database_failure
    end
    it 'renders html' do
      visit '/'
      expect(page).to have_css('span', class: 'name', text: 'Database')
      expect(page).to have_css('span', class: 'state', text: 'ERROR')
      expect(page).to have_css('div', class: 'message', text: 'RuntimeError')
    end
  end
end
