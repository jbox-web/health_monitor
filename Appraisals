# frozen_string_literal: true

appraise 'rails_7.2' do
  gem 'rails', '~> 7.2.0'
  gem 'sqlite3', '~> 1.5.0'

  # Fix:
  # warning: pstore was loaded from the standard library, but will no longer be part of the default gems since Ruby 3.5.0.
  # Add pstore to your Gemfile or gemspec.
  install_if '-> { Gem::Version.new(RUBY_VERSION) >= Gem::Version.new("3.5.0") }' do
    gem 'pstore'
  end
end

appraise 'rails_8.0' do
  gem 'rails', '~> 8.0.0'

  # Fix:
  # warning: pstore was loaded from the standard library, but will no longer be part of the default gems since Ruby 3.5.0.
  # Add pstore to your Gemfile or gemspec.
  install_if '-> { Gem::Version.new(RUBY_VERSION) >= Gem::Version.new("3.5.0") }' do
    gem 'pstore'
  end
end

appraise 'rails_8.1' do
  gem 'rails', '~> 8.1.0.rc1'

  # Fix:
  # warning: pstore was loaded from the standard library, but will no longer be part of the default gems since Ruby 3.5.0.
  # Add pstore to your Gemfile or gemspec.
  install_if '-> { Gem::Version.new(RUBY_VERSION) >= Gem::Version.new("3.5.0") }' do
    gem 'pstore'
  end
end
