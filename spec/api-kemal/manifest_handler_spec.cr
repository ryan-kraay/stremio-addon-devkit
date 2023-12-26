require "../../src/stremio-addon-devkit/api/manifest_handler"
require "../../src/stremio-addon-devkit/conf"
require "./spec_helper"

Kemal.run

Spectator.describe Stremio::Addon::DevKit::Api::ManifestHandler do
  alias Api = Stremio::Addon::DevKit::Api
  alias Conf = Stremio::Addon::DevKit::Conf

  let(manifest) { Conf::Manifest.build(
        id: "com.stremio.addon.example",
        name: "DemoAddon",
        description: "An example stremio addon",
        version: "0.0.1") do |conf|
          conf.catalogs << Conf::Catalog.new(
              type: Conf::ContentType::Movie,
              id: "movie4u",
              name: "Movies for you")
        end }

  let(router) { Api::ManifestHandler.new }
  before_each do
    reset_kemal do
      add_handler router
    end
  end

  describe "#route_catalogs" do
    it "creates a catalog.json endpoint" do
      accessed = false
      handler = ->( env: HTTP::Server::Context, addon: Api::CatalogRequest ) {
        print("hello")
        #accessed = true
      }
      #router.route_catalogs(manifest, &handler)
      router.route_catalogs(manifest) do |env, addon|
        accessed = true
      end

      get "/catalog/Movie/movie4u.json"
      expect(response.status_code).to eq(200)
      expect(accessed).to eq true
      # TODO check response.body
    end
  end

  describe "#bind" do
    it "binds a manifest to a callback" do
      accessed = false
      my_catalog_handler = ->( env: HTTP::Server::Context, addon: Api::CatalogRequest) {
        accessed = true
      }

      router.bind(manifest, catalog_handler: my_catalog_handler)

      get "/catalog/Movie/movie4u.json"
      expect(response.status.code).to eq(200)
      expect(accessed).to eq true
    end
  end
end
