# frozen_string_literal: true

# Mock out DJ
module Delayed
  class Job # rubocop:disable Lint/EmptyClass
  end
end

class TestClass # rubocop:disable Lint/EmptyClass
end

class CustomProvider < HealthMonitor::Providers::Base
end

# Mirrors real-world providers (e.g. Concerto's OVH SMS low-credits check) that
# signal a degraded-but-not-down state by raising a ServiceWarning.
class WarningProvider < HealthMonitor::Providers::Base
  def check!
    raise HealthMonitor::Error::ServiceWarning, 'low on credits'
  end
end

# Signals an indeterminate state by raising a ServiceUnknown.
class UnknownProvider < HealthMonitor::Providers::Base
  def check!
    raise HealthMonitor::Error::ServiceUnknown, 'state cannot be determined'
  end
end
