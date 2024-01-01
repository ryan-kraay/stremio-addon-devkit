require "./spec_helper"
require "../../src/stremio-addon-devkit/conf/manifest"

Spectator.describe Stremio::Addon::DevKit::Conf::Manifest do
  alias Manifest = Stremio::Addon::DevKit::Conf::Manifest

  alias ResourceType = Stremio::Addon::DevKit::Conf::ResourceType
  alias ContentType = Stremio::Addon::DevKit::Conf::ContentType

  alias Catalog = Stremio::Addon::DevKit::Conf::Catalog

  let(id) { "com.stremio.addon.example" }
  let(name) { "DemoAddon" }
  let(description) { "An example stremio addon" }
  let(version) { "0.0.1" }

  # allows us to extract a portion of the whole json document
  def mini_json(&)
    String.build do |io|
      json = JSON::Builder.new(io)
      json.document do
        yield json
      end
    end
  end

  describe "#initialize" do
    it "can exist" do
      expect do
        Manifest.new(id: id, name: name, description: description, version: version)
      end.to_not raise_error
    end

    it "can be constructed inline" do
      ran_callback = false
      expected_catalog_id = "movie4u"

      # Suitable for inline constructing within unit tests
      subject = Manifest.build(id, name, description, version) do |conf|
        ran_callback = true
        conf.catalogs << Catalog.new(ContentType::Movie, expected_catalog_id, "Movies for you")
      end

      expect(ran_callback).to eq(true)
      expect(subject.name).to eq(name)
      expect(subject.catalogs[0].id).to eq(expected_catalog_id)
    end
  end

  describe "#to_json" do
    let(catalog_type) { ContentType::Movie }
    let(catalog) { Catalog.new(catalog_type, "movie4u", "Movies for you") }
    subject { Manifest.new(id, name, description, version) }

    it "generates json" do
      empty_array = Array(String).new

      expect(subject.to_json).to eq({"id": id, "name": name, "description": description, "version": version, "catalogs": empty_array, "resources": empty_array, "types": empty_array, "idPrefixes": empty_array}.to_json)
    end

    it "populates resources and types based, when catalogs are added" do
      s = subject

      # No catalogs:  These fields will be empty
      expect(mini_json { |j| s.resources j }).to eq(Array(String).new.to_json)
      expect(mini_json { |j| s.types j }).to eq(Array(String).new.to_json)

      # Now add an entry
      s.catalogs << catalog

      # as we've included an entry in our catalogs, it should now be populated
      expect(mini_json { |json| s.resources json }).to eq([{"name": "catalog", "types": [catalog_type]}].to_json)
      expect(mini_json { |json| s.types json }).to eq([catalog_type].to_json)
    end
  end
end
