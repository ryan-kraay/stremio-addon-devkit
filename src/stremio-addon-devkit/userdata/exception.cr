module Stremio::Addon::DevKit::UserData
  class HeaderMalformed < Exception
    def initialize(message = "Malformed Header")
      super(message)
    end
  end

  class KeyRingCSV < Exception
    def initialize(message = "Failed to parse KeyRing CSV")
      super(message)
    end
  end
end
