require "./exception"
require "./v1"
require "base64"
require "lz4"
require "bitfields"

module Stremio::Addon::DevKit::UserData
  # A `Session` defines a way to encode/decode user content in a secure and url safe manner
  class Session(T)
    def initialize(@ring : KeyRing | KeyRing::Opt, @iv_static : T)
    end

    def encode(data, compress : Bool = true, random_generator = Random::Secure) : String
      latest = V1.new(@ring, @iv_static)
      Base64.urlsafe_encode( latest.encode(data.to_slice, compress, random_generator), padding: false )
    end

    def decode_to_bytes(data) : Bytes
      edata = Base64.decode(data)
      header = Header.new(edata.to_slice)

      case header.version
      when V1::Header::VERSION
        v1 = V1.new(@ring, @iv_static)
        v1.decode(edata)
      else
        raise HeaderMalformed.new("Unsupported Version #{header.version}")
      end
    end

    def decode(data) : String
      String.new(decode_to_bytes(data))
    end

    private class Header < BitFields
      # NOTE: BitFields' first entry is the LEAST Significant Bit
      # NOTE: This must be aligned on a per byte basis
      bf reserved : UInt8, 5
      # This MUST be the first byte for all of our header versions
      bf version : UInt8, 3
    end
  end
end
