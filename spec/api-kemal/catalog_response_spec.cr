require "./spec_helper"
require "../../src/stremio-addon-devkit/api/catalog_response"

Spectator.describe Stremio::Addon::DevKit::Api::CatalogResponse do
  alias CatalogResponse = Stremio::Addon::DevKit::Api::CatalogResponse
  alias Conf = Stremio::Addon::DevKit::Conf

  let(manifest) { Conf::Manifest.build(
                       id: "com.stremio.addon.example",
                       name: "DemoAddon",
                       description: "An example stremio addon",
                       version: "0.0.1") do |conf|
                    conf.catalogs << Conf::Catalog.new(Conf::ContentType::Movie, "movie4u", "Movies for you")
                  end }
  

  it "can be constructed" do
    expect do
      CatalogResponse.new(manifest, manifest.catalogs[0])
    end.to_not raise_error
  end
end
