require "./spec_helper"
require "../src/stremio-addon-devkit/userdata/session"

Spectator.describe Stremio::Addon::DevKit::UserData::Session do
  alias UserData = Stremio::Addon::DevKit::UserData

  let(keyring) { UserData::KeyRing.new("3:hello-must-be-atleast-32-characters-long") }
  let(iv_static) { "a-secret-only-this-app-knows" }
  subject { UserData::Session.new(keyring, iv_static) }

  describe "#initialize" do
    it "can be constructed with a keyring" do
      expect do
        subject
      end.to_not raise_error
    end

    it "can be constructed with keyring::disabled" do
      expect do
        UserData::Session.new(UserData::KeyRing::Opt::Disable, iv_static)
      end.to_not raise_error
    end
  end

  describe "#encode/#decode" do
    let(expected) { "grandma's apple pie recipe" }
    it "has basic functionality" do
      encrypted = String.new()
      expect do
        encrypted = subject.encode(expected, random_generator: Spectator.random)
      end.to_not raise_error()

      result = String.new()
      expect do
        result = subject.decode(encrypted)
      end.to_not raise_error()

      expect(result).to eq(expected)
    end
  end

  describe "base64.urlsafe_encode" do
    let(content) { "f" } # This string will deliberately introduce padding: Zg==
    it "has flexible padding" do
      no_padding = Base64.urlsafe_encode(content, padding = false)
      padding = Base64.urlsafe_encode(content, padding = true)

      # no_padding should always be shorter than padding
      expect(padding).to start_with(no_padding)
      expect(no_padding).to_not start_with(padding)

      expect(Base64.decode_string(no_padding)).to eq(content)
      expect(Base64.decode_string(padding)).to eq(content)
    end
  end
end
