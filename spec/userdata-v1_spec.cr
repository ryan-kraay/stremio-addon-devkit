require "./spec_helper"
require "../src/stremio-addon-devkit/userdata/v1"

# A class which will expose protected methods for unit testing
class V1Exposed(T) < Stremio::Addon::DevKit::UserData::V1(T)
  def initialize(keyring, iv_static : T)
    super(keyring, iv_static)
  end

  # Our exposed protected methods
  def compress(header : Header, data : Bytes) : Bytes
    super(header, data)
  end

  def decompress(header : Header, data : Bytes) : Bytes
    super(header, data)
  end

  def encrypt(header : Header, data : Bytes) : Bytes
    super(header, data)
  end

  def decrypt(data : Bytes) : Tuple(Header, Bytes)
    super(data)
  end
end

Spectator.describe Stremio::Addon::DevKit::UserData::V1 do
  alias UserData = Stremio::Addon::DevKit::UserData

  let(keyring) {
    UserData::KeyRing.new("1:this string must be at least 32-characters long fjdsklfjkdslfjklsadfjkldasfjkldsfjkldsfjklsafjklsdjfkl")
  }

  let(iv_static) { "an internal phrase only my app knows" }

  subject(v1) { V1Exposed.new keyring, iv_static }

  describe "#initialize" do
    subject { v1 }
    it "will initialize" do
      expect do
        subject
      end.to_not raise_error()
    end
  end

  describe "#compress / #decompress; compress = enabled" do
    let(content) { "my pyaload".to_slice }
    subject(header) { h = V1Exposed::Header.create(Spectator.random)
    h.compress = 1_u8
    h }

    it "compresses and decompresses" do
      compressed = Bytes[0]
      expect do
        compressed = v1.compress(header, content)
      end.to_not raise_error()

      # The content is compressed
      expect(compressed).to_not eq(content)

      decompressed = Bytes[0]
      expect do
        decompressed = v1.decompress(header, compressed)
      end.to_not raise_error()

      expect(decompressed).to eq(content)
    end
  end

  describe "#compress / #decompress; compress = disabled" do
    let(content) { "my pyaload".to_slice }
    subject(header) { h = V1Exposed::Header.create(Spectator.random)
    h.compress = 0_u8
    h }

    it "compresses and decompresses" do
      compressed = Bytes[0]
      expect do
        compressed = v1.compress(header, content)
      end.to_not raise_error()

      # The content is compressed
      expect(compressed).to eq(content)

      decompressed = Bytes[0]
      expect do
        decompressed = v1.decompress(header, compressed)
      end.to_not raise_error()

      expect(decompressed).to eq(content)
    end
  end

  describe "#encrypt / decrypt; encryption = enabled" do
    let(content) { "my payload".to_slice }
    subject(header) { h = V1Exposed::Header.create(Spectator.random)
    h.keyring = 1 # This matches the index of our @keyring
    h }

    it "encrypts and decrypts" do
      encrypted = Bytes[0]
      expect do
        encrypted = v1.encrypt(header, content)
      end.to_not raise_error()

      # The content is encrypted
      expect(encrypted).to_not eq(content)

      decrypted_data = Bytes[0]
      decrypted_header = V1Exposed::Header.create(Spectator.random)
      expect do
        decrypted_header, decrypted_data = v1.decrypt(encrypted)
      end.to_not raise_error()

      expect(decrypted_header.to_slice).to eq(header.to_slice)
      expect(decrypted_data).to eq(content)
    end

    it "fails when encrypting with an invalid keyring" do
      h = header
      h.keyring = 0 # This does not exist in our index
      expect(keyring[h.keyring]).to be_nil

      expect do
        v1.encrypt(h, content)
      end.to raise_error(IndexError)

      # TODO: test encrypt with an invalid index
      # TODO: test decrypt with an invalid index header
    end

    it "fails when decrypting with an invalid keyring" do
      encrypted = v1.encrypt(header, content)

      # We'll construct a new v1 w/ a different keyring
      keyring_bad = UserData::KeyRing.new("0:lalalalalala")
      v1_bad = V1Exposed.new keyring_bad, iv_static

      expect do
        v1_bad.decrypt(encrypted)
      end.to raise_error(IndexError)
    end
  end
  describe "#encrypt / decrypt; encryption = disabled" do
    let(content) { "my payload".to_slice }
    subject(header) { h = V1Exposed::Header.create(Spectator.random)
    h.keyring = UserData::KeyRing::Opt::Disable.to_u8
    h }

    it "encrypts and decrypts" do
      encrypted = Bytes[0]
      expect do
        encrypted = v1.encrypt(header, content)
      end.to_not raise_error()

      # The content is encrypted
      expect(encrypted + V1Exposed::Header::BYTESIZE).to eq(content)

      decrypted_data = Bytes[0]
      decrypted_header = V1Exposed::Header.create(Spectator.random)
      expect do
        decrypted_header, decrypted_data = v1.decrypt(encrypted)
      end.to_not raise_error()

      expect(decrypted_header.to_slice).to eq(header.to_slice)
      expect(decrypted_data).to eq(content)
    end
  end

  describe "#encode/#decode" do
    let(expected) { "top secret".to_slice }

    it "has basic functionality" do
      encoded = Bytes[0]
      expect do
        encoded = v1.encode(expected, random_generator: Spectator.random)
      end.to_not raise_error()

      results = Bytes[0]
      expect do
        results = v1.decode(encoded)
      end.to_not raise_error()

      expect(results).to eq(expected)
    end

    it "raises an error when given an empty keyring" do
      expect do
        V1Exposed.new(UserData::KeyRing.new, iv_static).encode(expected, compress: true, random_generator: Spectator.random)
      end.to raise_error(IndexError)
    end
  end
end
