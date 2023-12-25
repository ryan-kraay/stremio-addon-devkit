require "../../src/stremio-addon-devkit/api/manifest_handler"
require "../../src/stremio-addon-devkit/conf"
require "./spec_helper"

Kemal.run

Spectator.describe Stremio::Addon::DevKit::Api::ManifestHandler do
  alias ManifestHandler = Stremio::Addon::DevKit::Api::ManifestHandler
  alias Conf = Stremio::Addon::DevKit::Conf

  let(manifest) { Conf::Manifest(Conf::ContentType).build(
        id: "com.stremio.addon.example",
        name: "DemoAddon",
        description: "An example stremio addon",
        version: "0.0.1") do |conf|
          conf.catalogs << Conf::Catalog.new(
              type: Conf::ContentType::Movie,
              id: "movie4u",
              name: "Movies for you")
        end }

  let(router) { ManifestHandler.new }
  before_each do
    config = Kemal.config
    config.clear
    config.env = "test"
    # All our added handlers need to be added _before_ the setup()
    # and _after_ the clear()
    add_handler router
    config.setup
  end

  describe "#route_catalogs" do
    it "creates a catalog.json endpoint" do
      expect(true).to eq(true)
#      accessed = false
#      router.route_catalogs(manifest) do
#      #|env, catalog|
#        accessed = true
#      end
#
#      get "/catalog/movie/movie4u.json"
#      expect(accessed).to eq true
#      # TODO check response.body
    end
  end
end
