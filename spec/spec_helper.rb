# frozen_string_literal: true

require 'bundler/setup'
require 'people_doc'
require 'faker'
require 'simplecov'
require 'webmock/rspec'

Dir[
  File.join(File.dirname(__FILE__), 'support', '**', '*.rb')
].each do |file_name|
  require file_name
end

SimpleCov.start

RSpec.configure do |config|
  config.disable_monkey_patching!
  config.example_status_persistence_file_path = '.rspec_status'
  config.expect_with :rspec do |expectations|
    expectations.include_chain_clauses_in_custom_matcher_descriptions = true
    expectations.syntax = :expect
  end
  config.mock_with :rspec do |mocks|
    mocks.verify_partial_doubles = true
  end
  config.order = :random
end
