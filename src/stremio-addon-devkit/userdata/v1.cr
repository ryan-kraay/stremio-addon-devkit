require "bitfields"
require "random/secure"
require "openssl/digest"
require "openssl/cipher"
require "base64"
require "lz4/writer"
require "./keyring"
require "./exception"

module Stremio::Addon::DevKit::UserData
  class V1(T)
    # Our enrypted userdata contains a custom header.  We can support different versions of these header.
    # This class defines Version 1.
    # WARNING: Headers are stored and transmitted as big endian (aka: network byte order)
    class Header < BitFields
      # NOTE: BitFields' first entry is the LEAST Significant Bit

      #
      # HIGH BYTE - LSB first
      #

      # Reserved for future expansion
      bf reserve : UInt8, 1
      # Refers to the position in `Stremio::Addon::DevKit::UserData::KeyRing`
      bf keyring : UInt8, 3
      # Toggles if compression was used or not
      bf compress : UInt8, 1
      # Space to store which Header version was used
      # WARNING: Required for ALL headers and MUST be the Most Significant Bit
      bf version : UInt8, 3

      #
      # BYTE BOUNDARY
      #
      # LOW BYTE - LSB first
      #

      # A fragement of the random Initial Vector used for encryption
      bf iv_random : UInt8, 8

      #
      # END BIT-VECTOR
      #

      # The version we register as (must fit within `@version`)
      VERSION = 1_u8
      # How many bytes this header takes
      BYTESIZE = 2

      # Returns a `Header` constructed with `bytes`
      # Paramaters:
      #  * `bytes`: The header in network byte order, meaning bytes[0] contains the "high" bits
      #
      # WARNING: the use of `Header.new()` should be avoided (and for some reason we cannot create our own initialize()
      def self.create(bytes : Bytes)
        Header.new(bytes)
      end

      #
      # Returns an empty `Header` header with the version set
      #
      # Parameters:
      #  * `random_generator` uses a pseudo or real random number generator, `::Random#new` can be used for unit tests
      # WARNING: the use of `Header.new()` should be avoided (and for some reason we cannot create our own initialize()
      def self.create(random_generator = Random::Secure)
        rtn = Header.new Bytes[0, 0]
        rtn.version = Header::VERSION
        rtn.iv_random = {% begin %}
                          b = Bytes[0]
                          random_generator.random_bytes(b)
                          b[0]
                        {% end %}
        rtn
      end

      # Returns a cryptocraphically random initial vector
      # Paramaters:
      #  * `iv_static`: An optional fragement of the initial vector.  The `iv_random` + `iv_static` create enough entropy that we can build a suitable iv
      def iv(iv_static)
        hash = OpenSSL::Digest.new("SHA256")
        hash.update(Bytes[iv_random])
        hash.update(iv_static)
        hash.final
        # hash.hexfinal
      end

      # :ditto:
      def iv(iv_static : ::Nil)
        hash = OpenSSL::Digest.new("SHA256")
        hash.update(Bytes[iv_random])
        hash.final
        # hash.hexfinal
      end
    end # END of `Header`

    # Constructs UserData Version 1 Interface
    #
    # Parameters:
    #  - `@ring` can either be a `KeyRing` or `KeyRing::Opt::Disable`
    #  - `@iv_static` a static portion of the initial vector used to encrypt the user data
    #
    # WARNING: Using `KeyRing::Opt::Disable` means that encryption will *not* be used
    def initialize(@ring : KeyRing | KeyRing::Opt, @iv_static : T)
    end

    def encode(data, compress : Bool = true, random_generator = Random::Secure) : Bytes
      header = Header.create random_generator
      header.compress = compress == true ? 1_u8 : 0_u8
      if @ring.is_a?(KeyRing)
        # we want to find all the positions in our keyring, where the value is not nil
        used_positions = @ring.as(KeyRing).map_with_index do |secret, pos|
          # Combine our values with their index/position
          {pos, secret}
        end.select do |pair|
          # Filter out values that are nil
          !pair[1].nil?
        end.map do |pair|
          # return the index
          pair[0]
        end
        # Raise an error if used_positions is empty. aka our KeyRing is empty
        raise IndexError.new("Empty KeyRing: use KeyRing::Opt::Disable, if intended") if used_positions.empty?

        # Randomly choose from one of the available indexes
        index = random_generator.rand(0..used_positions.size - 1)
        header.keyring = used_positions[index].to_u8 # Our chosen keyring
      elsif @ring.is_a?(KeyRing::Opt) && @ring.as(KeyRing::Opt) == KeyRing::Opt::Disable
        header.keyring = KeyRing::Opt::Disable.value.to_u8
      else
        raise Exception.new("Unreachable")
      end
      encrypt(header, compress(header, data.to_slice))
    end

    def decode(data) : Bytes
      decompress(*decrypt(data.to_slice))
    end

    # Returns a byte stream of compressed content
    #
    # Parameters:
    #  - `data`: The data to (optionally) compress
    #  - `header`: Contains `header.compress` to determine if compression is desired or not
    protected def compress(header : Header, data : Bytes) : Bytes
      return data if header.compress == 0_u8

      buf = IO::Memory.new
      # enable compression
      Compress::LZ4::Writer.open(buf) do |br|
        br.write data
      end
      buf.rewind

      buf.to_slice
    end

    protected def decompress(header : Header, edata : Bytes) : Bytes
      return edata if header.compress == 0_u8

      # TODO: I fear we're duplicating edata as we put it into buf
      buf = IO::Memory.new(edata)
      results = Compress::LZ4::Reader.open(buf) do |br|
        br.gets_to_end
      end

      results.to_slice
    end

    # Returns a byte stream of encrypted content
    #
    # Parameters:
    #   - `data`: The data to encrypt
    #   - `header`: Contains the instructions for how to encrypt `data`
    protected def encrypt(header : Header, data : Bytes) : Bytes
      buf = IO::Memory.new
      buf.write(header.to_slice) # Write our header first in plain-text
      if @ring.is_a?(KeyRing) && header.keyring != KeyRing::Opt::Disable.to_u8
        key_or_nil = @ring.as(KeyRing)[header.keyring]
        raise IndexError.new("KeyRing Index #{header.keyring} is nil") if key_or_nil.is_a?(::Nil)

        cipher = OpenSSL::Cipher.new("aes-256-cbc")
        cipher.encrypt
        cipher.key = key_or_nil.as(String).to_slice
        cipher.iv = header.iv(@iv_static)

        buf.write(cipher.update data) # Write our payload
        buf.write(cipher.final)       # Finalize the payload
      elsif @ring.is_a?(KeyRing::Opt) && @ring.as(KeyRing::Opt) == KeyRing::Opt::Disable || header.keyring == KeyRing::Opt::Disable.to_u8
        buf.write(data) # Write our payload
      else
        raise Exception.new("Unreachable")
      end
      buf.rewind

      buf.to_slice
    end

    protected def decrypt(edata : Bytes) : Tuple(Header, Bytes)
      raise HeaderMalformed.new("Malformed Header Size #{edata.bytesize}") if edata.bytesize < Header::BYTESIZE

      header = Header.new(edata)

      raise HeaderMalformed.new("Incompatible version, recieved:#{header.version} expected:#{Header::VERSION}") if header.version != Header::VERSION
      edata += Header::BYTESIZE # skip over the size of our header

      return {header, edata} if header.keyring == KeyRing::Opt::Disable.to_u8

      raise Exception.new("Unreachable: Unknown @ring") unless @ring.is_a?(KeyRing)

      key = @ring.as(KeyRing)[header.keyring]
      raise IndexError.new("KeyRing Index #{header.keyring}") if key.is_a?(::Nil)

      cipher = OpenSSL::Cipher.new("aes-256-cbc")
      cipher.decrypt
      cipher.key = key.as(String).to_slice
      cipher.iv = header.iv(@iv_static)

      buf = IO::Memory.new
      buf.write(cipher.update(edata))
      buf.write(cipher.final)
      buf.rewind

      {header, buf.to_slice}
    end
  end
end
