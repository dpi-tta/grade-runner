require 'rspec'
require 'grade_runner'
require 'rspec/core/formatters/documentation_formatter'

# Require formatters directly
require_relative '../lib/grade_runner/formatters/hint_formatter.rb'
require_relative '../lib/grade_runner/formatters/json_output_formatter.rb'

RSpec.configure do |config|
  # Basic configuration
  config.color = true
  config.order = :random
  config.mock_with :rspec

  # Clear out mocks between tests
  config.mock_with :rspec do |mocks|
    mocks.verify_partial_doubles = true
  end
end
