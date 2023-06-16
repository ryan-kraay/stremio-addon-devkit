require "./spec_helper"
require "../src/stremio-addon-devkit/userdata/keyring"

Spectator.describe Stremio::Addon::DevKit::UserData::KeyRing do
  alias UserData = Stremio::Addon::DevKit::UserData

  let(expected) { Array(String?).new(UserData::KeyRing::Opt::Disable.value - 1, nil) }

  describe "#initialize" do
    subject { UserData::KeyRing.new }

    it "has an empty constructor" do
      # expect(subject).to have_size(UserData::KeyRing::Opt::Disable.value - 1)
      is_expected.to match_array(expected)
    end
  end

  describe "#initialize w/ csv" do
    subject(csv) { UserData::KeyRing.new("4:world,2:hello") }

    it "imports a CSV string" do
      expect do
        csv
      end.to_not raise_error()
      expected[2] = "hello"
      expected[4] = "world"

      expect(csv).to eq(expected)
    end

    sample ["hello:world", "hello:hello:world", "test", "300:hello", "10:hello", "1:hello,x:invalid", "1:"].each do |invalid_csv|
      it "errors with an invalid CSV" do
        expect do
          UserData::KeyRing.new(invalid_csv)
        end.to raise_error(UserData::KeyRingCSV)
      end
    end
  end

  describe "#=operator" do
    it "is assignable" do
      subject[3] = "hello"

      failure = expected.clone
      failure[2] = "hello"

      expect(subject).to_not eq(failure)

      expected[3] = "hello"
      expect(subject).to eq(expected)
    end
  end
end
