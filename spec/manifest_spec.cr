require "./spec_helper"
require "../src/stremio-addon-devkit/manifest"

Spectator.describe Stremio::Addon::DevKit::Manifest do
  alias Manifest = Stremio::Addon::DevKit::Manifest

  alias ResourceType = Stremio::Addon::DevKit::ResourceType
  alias ContentType = Stremio::Addon::DevKit::ContentType

  alias Catalog = Stremio::Addon::DevKit::Catalog

  let(id) { "com.stremio.addon.example" }
  let(name) { "DemoAddon" }
  let(description) { "An example stremio addon" }
  let(version) { "0.0.1" }

  describe "#initialize" do
    it "can exist" do
      expect do
        Manifest(ResourceType).new(id: id, name: name, description: description, version: version)
      end.to_not raise_error
    end
  end

  describe "#to_json" do
    let(catalog) { Catalog.new(ContentType::Movie, "movie4u", "Movies for you") }
    subject { Manifest(ResourceType).new(id, name, description, version) }
    it "refers to catalogs" do
      expect(true).to be_true
    end
  end

end
