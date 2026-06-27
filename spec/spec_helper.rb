# frozen_string_literal: true

require "bundler/setup"
require "pry"
require "esse/pagy"
require "esse/rspec"

# Pagy < 43 ships the extras system; Pagy 43 removed it.
begin
  require "pagy/extras/overflow"
rescue LoadError
  nil
end

# Pagy 43 removed the Backend/Frontend mixins. Probe availability by referencing
# the constant (a bare `defined?` would not trigger autoload on older Pagy).
PAGY_BACKEND_AVAILABLE = begin
  Pagy::Backend
  true
rescue NameError
  false
end

# `skip:` metadata value for the Backend-only example groups.
BACKEND_SKIP = PAGY_BACKEND_AVAILABLE ? false : "Pagy::Backend was removed in Pagy 43"

require "support/app_mock"

RSpec.configure do |config|
  config.example_status_persistence_file_path = ".rspec_status"
  config.disable_monkey_patching!
  config.expect_with :rspec do |c|
    c.syntax = :expect
  end
end
