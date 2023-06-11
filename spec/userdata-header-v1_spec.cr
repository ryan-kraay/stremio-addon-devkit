require "./spec_helper"
require "../src/stremio-addon-devkit/userdata/header/v1"
require "io/memory"

Spectator.describe Stremio::Addon::DevKit::UserData::Header::V1 do
  alias UserData = Stremio::Addon::DevKit::UserData

  let( expected_version_hi ) { 32_u8 } # (1 << 5) aka |00100000|
  let( expected_iv_lo ) { 1_u8  } # (1 << 0) aka |00000001|
  let( expected_header ) { 8193_u16 } # (1 << 13) & (1 << 0) aka |00100000|00000001|

  subject { UserData::Header::V1.create(Bytes[expected_version_hi, expected_iv_lo] ) }
#  subject { UserData::Header::V1.new(Bytes[expected_version_hi, expected_iv_lo]) }

  describe "#create" do
		it "can be constructed with a known iv" do
			expect(subject.iv_random).to eq(expected_iv_lo)
		end
		it "can be constructed with a known version" do
			expect(subject.version).to eq(UserData::Header::V1::VERSION)
		end
	end

	describe "#initialize" do
		subject { UserData::Header::V1.create }
		it "will have the version set" do
			expect(subject.version).to eq(UserData::Header::V1::VERSION)
		end
	end

	describe "#to_slice" do
		it "will export itself as a Byte Array" do
			expect(subject.to_slice).to eq(Bytes[expected_version_hi, expected_iv_lo])
		end
	end

  describe "#iv" do

		subject { result = UserData::Header::V1.create
							result.iv_random = 97_u8 # ascii "a"
							result
						}
		it "will only use the iv_random" do
      # "a" will yield: ca978112ca1bbdcafac231b39a23dc4da786eff8147c4e72b9807785afee48bb, which is the same as expected
      expected = Bytes[202, 151, 129, 18, 202, 27, 189, 202, 250, 194, 49, 179, 154, 35, 220, 77, 167, 134, 239, 248, 20, 124, 78, 114, 185, 128, 119, 133, 175, 238, 72, 187]

			expect(subject.iv(nil)).to eq(expected)
    end
		it "will use iv_static" do
			# Using the test vectors from: http://www.nsrl.nist.gov/testdata/
			# "abc" should yield:  BA7816BF 8F01CFEA 414140DE 5DAE2223 B00361A3 96177A9C B410FF61 F20015AD
			expected = Bytes[186, 120, 22, 191, 143, 1, 207, 234, 65, 65, 64, 222, 93, 174, 34, 35, 176, 3, 97, 163, 150, 23, 122, 156, 180, 16, 255, 97, 242, 0, 21, 173]
			expect(subject.iv(Bytes[98_u8, 99_u8])).to eq(expected) # 'b' = 98, 'c' =  99  # TODO:  why can I not use 'a'.to_u8(10)
		end
	end

	# Some debugging/exploring Endianness w/ Crystal	
  it "tests little-endianiness" do
    expected = 1_u16
    io = IO::Memory.new(Bytes[0, 1], writable = false)
    expect( io.read_bytes(UInt16, IO::ByteFormat::BigEndian) ).to eq(expected)
  end
  it "tests little-endianiness again" do
    io = IO::Memory.new(Bytes[expected_version_hi, expected_iv_lo], writable = false)
    expect( io.read_bytes(UInt16, IO::ByteFormat::BigEndian) ).to eq(expected_header)
  end
end
