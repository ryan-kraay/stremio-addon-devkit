module Stremio::Addon::DevKit::UserData

  class HeaderMalformed < Exception
    def initialize(message = "Malformed Header")
      super(message)
    end
  end

end

