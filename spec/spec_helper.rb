# frozen_string_literal: true

require "bundler/setup"
require "pry"
require "esse/pagy"
require "esse/rspec"
require "pagy/extras/overflow"

require "support/app_mock"

RSpec.configure do |config|
  config.example_status_persistence_file_path = ".rspec_status"
  config.disable_monkey_patching!
  config.expect_with :rspec do |c|
    c.syntax = :expect
  end
end
