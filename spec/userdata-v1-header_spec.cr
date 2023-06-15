require "./spec_helper"
require "../src/stremio-addon-devkit/userdata/v1"
require "io/memory"


Spectator.describe Stremio::Addon::DevKit::UserData::V1::Header do
  alias UserData = Stremio::Addon::DevKit::UserData

  let(expected_version_hi) { 32_u8 } # (1 << 5) aka |00100000|
  let(expected_iv_lo) { 1_u8 }       # (1 << 0) aka |00000001|
  let(expected_header) { 8193_u16 }  # (1 << 13) & (1 << 0) aka |00100000|00000001|

  # WARNING: Spectator.random does not actually use a seed value when --order <seed> is used
  # TODO: Investigate and file a bug report
  subject { UserData::V1::Header.create(Spectator.random) }

  describe "#create" do
    subject { UserData::V1::Header.create(Bytes[expected_version_hi, expected_iv_lo]) }
  #  subject { UserData::V1::Header.new(Bytes[expected_version_hi, expected_iv_lo]) }

    it "can be constructed with a known iv" do
      expect(subject.iv_random).to eq(expected_iv_lo)
    end
    it "can be constructed with a known version" do
      expect(subject.version).to eq(UserData::V1::Header::VERSION)
    end
    it "can import what it exports" do
      expect(UserData::V1::Header.create(subject.to_slice).to_s).to eq(subject.to_s)
    end
    it "can import more bytes than necessary" do
      expect(UserData::V1::Header.create(Bytes[expected_version_hi, expected_iv_lo, 255_u8, 100_u8]).to_s).to eq(subject.to_s)
    end
  end

  describe "#initialize" do
    subject { UserData::V1::Header.create }
    it "will have the version set" do
      expect(subject.version).to eq(UserData::V1::Header::VERSION)
    end
    it "will have an iv_random set" do
      expect(subject.iv_random).to_not eq(0)
    end
  end

  describe "#initialize w/ seed" do
    let(seed) { 12345 }

    it "works with a fixed seed" do
      generator1 = Random.new(seed)
      generator2 = Random.new(seed)

      expected_iv = UserData::V1::Header.create(generator2).iv_random
      expect( UserData::V1::Header.create(generator1).iv_random ).to eq( expected_iv )

      # by using the random number generator again, we should have a different iv - this tests that we are indeed generating random iv's
      expect( UserData::V1::Header.create(generator2).iv_random).to_not eq(expected_iv)
    end
  end

  describe "#to_slice" do
    subject { UserData::V1::Header.create(Bytes[expected_version_hi, expected_iv_lo]) }
    it "will export itself as a Byte Array" do
      expect(subject.to_slice).to eq(Bytes[expected_version_hi, expected_iv_lo])
    end
  end

  describe "#iv" do
    subject { result = UserData::V1::Header.create
    result.iv_random = 97_u8 # ascii "a"
    result }
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
    expect(io.read_bytes(UInt16, IO::ByteFormat::BigEndian)).to eq(expected)
  end
  it "tests little-endianiness again" do
    io = IO::Memory.new(Bytes[expected_version_hi, expected_iv_lo], writable = false)
    expect(io.read_bytes(UInt16, IO::ByteFormat::BigEndian)).to eq(expected_header)
  end
end
