require "kemal"
require "spec-kemal"
require "../spec_helper"

def reset_kemal(&block)
  config = Kemal.config
  config.clear
  config.env = "test"
  config.always_rescue = false  # supress the kemal error page and raise exceptions

  # All our added handlers need to be added _before_ the setup()
  # and _after_ the clear()
  yield config

  config.setup
end
