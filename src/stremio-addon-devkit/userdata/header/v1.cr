require "bitfields"
require "random/secure"
require "openssl/digest"

module Stremio::Addon::DevKit::UserData::Header

  # Our enrypted userdata contains a custom header.  We can support different versions of these header.
  # This class defines Version 1.
  # WARNING: Headers are stored and transmitted as big endian (aka: network byte order)
  class V1 < BitFields
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

		# Returns a `V1` constructed with `bytes`
		# Paramaters:
		#  * `bytes`: The header in network byte order, meaning bytes[0] contains the "high" bits
		#
		# WARNING: the use of `V1.new()` should be avoided (and for some reason we cannot create our own initialize()
    def self.create(bytes : Bytes)
			V1.new(bytes)
    end

		#
		# Returns an empty `V1` header with the version set
		#
		# WARNING: the use of `V1.new()` should be avoided (and for some reason we cannot create our own initialize()
		def self.create
			rtn = V1.new Bytes[0, 0]
			rtn.version = V1::VERSION
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
			#hash.hexfinal
		end
		# :ditto:
		def iv(iv_static : ::Nil)
			hash = OpenSSL::Digest.new("SHA256")
			hash.update(Bytes[iv_random])
			hash.final
			#hash.hexfinal
		end

  end
end
