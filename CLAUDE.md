# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this is

`health_monitor` is a mountable Rails engine (gem) that exposes a `/check` endpoint returning the health of configured backend services (database, cache, Redis, Sidekiq, Resque, Delayed Job, plus custom providers). The response is HTML, JSON, or XML, with an HTTP status of `200 OK` or `503 Service Unavailable` depending on the aggregate result.

## Commands

Always go through the project binstubs (`bin/rspec`, `bin/rubocop`, `bin/rake`, `bin/appraisal`) — never `bundle exec` nor a globally installed gem.

- Run the full test suite: `bin/rspec`
- Run a single spec file: `bin/rspec spec/lib/health_monitor/providers/redis_spec.rb`
- Run a single example by line: `bin/rspec spec/lib/health_monitor/providers/redis_spec.rb:42`
- Lint: `bin/rubocop` (config in `.rubocop.yml`)
- Auto-watch tests: `bin/guard` (RSpec via Guardfile)
- Default rake task runs the specs: `bin/rake`

### Multi-version testing (Appraisal)

The gem is tested against several Rails versions defined in `Appraisals` (Rails 7.2, 8.0, 8.1), generated into `gemfiles/*.gemfile`. CI (`.github/workflows/ci.yml`) runs the matrix across Ruby 3.2–4.0.

- Regenerate gemfiles after editing `Appraisals`: `bin/appraisal install`
- Run specs under one Rails version: `bin/appraisal rails_8.1 rspec`
- Locally the default `bin/rspec` uses the root `Gemfile`; CI sets `BUNDLE_GEMFILE` to a `gemfiles/*.gemfile`.

## Architecture

Zeitwerk-loaded (`lib/health_monitor.rb`), the engine self-configures on boot via `Engine#before_initialize` calling `HealthMonitor.configure`.

**Request flow:** route (`config/routes.rb`) → `HealthMonitor::HealthController#check` → `HealthMonitor.check(request:, params:)` → each provider's `check!`. The controller renders HTML/JSON/XML and returns the status symbol from the aggregate result as the HTTP status.

**The provider contract (`providers/base.rb`)** is the core extension point:
- A provider subclasses `HealthMonitor::Providers::Base` and implements `check!`. A check is considered *failed* when `check!` raises. Raising `Error::ServiceWarning` yields status `WARNING`; any other exception yields `ERROR`; no exception yields `OK` (see `HealthMonitor.provider_result`).
- Optional per-provider configuration: a provider defines a nested `Configuration` class and overrides the class method `configuration_class` to return it. `Base.configure` then instantiates it into a class-level `@global_configuration`, and each provider instance receives it as `self.configuration`. Providers without a `configuration_class` are non-configurable.
- `provider_name` defaults to the demodulized class name and is used both for the result payload and for the `?providers[]=` filter (matched case-insensitively, downcased).

**Enabling providers (`configuration.rb`):** the `Configuration` object holds a `Set` of provider classes. The built-in provider names in `PROVIDERS` (`cache database redis resque sidekiq`) are turned into instance methods via `class_eval` — calling e.g. `config.redis` lazily `require`s and registers the provider. **The database provider is registered by default** in `Configuration#initialize`; disable it with `config.no_database`. Custom providers go through `add_custom_provider`, which enforces the `Base` subclass contract.

**ConnectionPool support:** the Redis provider (`providers/redis.rb`) detects whether the configured connection is a `ConnectionPool` and wraps every call in `@redis.with { ... }` accordingly. Mirror this pattern in any provider accepting an injected connection.

## Test layout

- `spec/dummy/` is a minimal host Rails app the engine mounts into; controller and feature specs exercise the real `/check` endpoint through it.
- `spec/support/providers.rb` and `spec/support/models.rb` hold shared provider/model fixtures.
- Backend fakes: `rediska` (Redis), `timecop`, `database_cleaner`, `capybara` for feature specs.

## Conventions

- All Ruby files start with `# frozen_string_literal: true` and end with a trailing blank line.
- RuboCop enforces table-aligned hashes, `consistent_comma` trailing commas, and explicit hash-rocket / colon styles — match the surrounding style rather than reformatting.
- Version lives in `lib/health_monitor/version.rb` (`VERSION::STRING`); the gemspec and README release tag reference it.
