require 'chefspec'
require 'chefspec/berkshelf'

ChefSpec::Coverage.start!

RSpec.configure do |config|
  config.expect_with :rspec do |c|
    # disable the `should` syntax
    c.syntax = :expect
  end
  config.platform = 'redhat'
  config.version = '7.8'
end
