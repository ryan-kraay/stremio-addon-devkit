require "./spec_helper"
require "../src/stremio-addon-devkit/userdata/v1"

Spectator.describe Stremio::Addon::DevKit::UserData::V1 do
  alias UserData = Stremio::Addon::DevKit::UserData

  let(keyring) {
    kr = UserData::KeyRing.new
    kr[1] = "this string must be at least 32-characters long fjdsklfjkdslfjklsadfjkldasfjkldsfjkldsfjklsafjklsdjfkl"
    kr
  }

  let(iv_static) { "an internal phrase only my app knows" }
    
  subject { UserData::V1.new keyring, iv_static }

  describe "#initialize" do
    it "will initialize" do
      expect do
        subject
      end.to_not raise_error()
    end
  end

  describe "#encode" do
    let( expected ) { "top secret" }
    
    it "encodes" do
      result = subject.encode(expected, random_generator: Spectator.random)
      expect(result).to_not be_empty

      puts result

      # Decode the base64
      remove_base64 = Bytes[]
      expect do
        remove_base64 = Base64.decode(result)
      end.to_not raise_error()
      expect(remove_base64).to_not be_empty
      puts remove_base64.to_slice
      header = UserData::V1::Header.create()
      expect do
        header = UserData::V1::Header.create(remove_base64)
        #header = UserData::V1::Header.create(Bytes[ remove_base64[0], remove_base64[1] ])
      end.to_not raise_error()
      puts header.to_s
      expect(header.version).to eq(UserData::V1::Header::VERSION)

      # Remove the aes
#      remove_aes = {% begin %}
#        cipher = OpenSSL::Cipher.new("aes-256-cbc")
#        cipher.decrypt
#        cipher.key = keyring[ 
#      {% end %}

    end

    it "raises an error when given an empty keyring" do
      expect do
        UserData::V1.new(UserData::KeyRing.new, iv_static).encode(expected, random_generator: Spectator.random)
      end.to raise_error(IndexError)
    end
  end
end
