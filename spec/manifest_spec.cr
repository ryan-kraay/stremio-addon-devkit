require "./spec_helper"
require "../src/stremio-addon-devkit/manifest"

Spectator.describe Stremio::Addon::DevKit::Manifest do
  alias Manifest = Stremio::Addon::DevKit::Manifest

  alias ResourceType = Stremio::Addon::DevKit::ResourceType
  alias ContentType = Stremio::Addon::DevKit::ContentType

  alias Catalog = Stremio::Addon::DevKit::Catalog

  describe "#initialize" do
    it "can exist" do
      expect(true).to be_true
    end
  end
end
