# frozen_string_literal: true

require 'factory_bot'

RSpec.configure do |config|
  config.include FactoryBot::Syntax::Methods
end

Dir[
  File.join(File.dirname(__FILE__), '../', 'factories', '**', '*.rb')
].each do |file_name|
  require file_name
end
