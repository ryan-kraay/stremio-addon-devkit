require "./keyring"
require "base64"
require "lz4"

module Stremio::Addon::DevKit::UserData
  # A `Session` defines a way to encode/decode user content in a secure and url safe manner
  class Session
    def initialize(@ring : KeyRing | KeyRing::Opt)
    end

    def encode(data, compress : Bool = true) : String
      # 1. Compress (or not) the content
      # 2. Encrypt the compressed content : https://www.reddit.com/r/crystal_programming/comments/ak39oh/how_to_use_opensslcipher_to_encrypt_data_with_aes/
      # 3. Add a Header
      # 4. Base64 encode the content
      # Base64.urlsafe_encode data
      ""
      # content = begin
      #  compressed = Compress::LZ4.encode(data)

      # end
      # Base64.urlsafe_encode(content, padding = false)
    end

    def decode(data) : Bytes
      Bytes[0]
    end

    def decode_to_s(data) : String
      String.new(decode(data))
    end
  end
end
