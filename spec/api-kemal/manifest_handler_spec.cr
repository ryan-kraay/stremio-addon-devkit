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
    it "executes a proc when accessing a catalog endpoint" do
      accessed = false
      handler = ->( env: HTTP::Server::Context, addon: Api::CatalogRequest ) {
        accessed = true
      }
      router.route_catalogs(manifest, &handler)

      get "/catalog/movie/movie4u.json"
      expect(response.status_code).to eq(200)
      expect(accessed).to eq true
    end

    it "executes a block when accessing a catalog endpoint" do
      accessed = false
      router.route_catalogs(manifest) do |env, addon|
        accessed = true
      end

      get "/catalog/movie/movie4u.json"
      expect(response.status_code).to eq(200)
      expect(accessed).to eq true
    end
  end

  describe "#bind" do
    it "binds a manifest to a callback" do
      accessed = false
      my_catalog_handler = ->( env: HTTP::Server::Context, addon: Api::CatalogRequest) {
        accessed = true
      }

      router.bind(manifest) do
        set_catalog_callback &my_catalog_handler
      end

      get "/catalog/movie/movie4u.json"
      expect(response.status.code).to eq(200)
      expect(accessed).to eq true
    end

		it "does not allow the same manifest to be rebounded" do
      my_catalog_handler = ->( env: HTTP::Server::Context, addon: Api::CatalogRequest) { }

			# The first invocation should create all the necessary routes
			expect do
				router.bind(manifest) do
          set_catalog_callback &my_catalog_handler
        end
			end.to_not raise_error

      # Second invocation will complain that the routes already exist
			expect do
				router.bind(manifest) do
          set_catalog_callback &my_catalog_handler
        end
			end.to raise_error Radix::Tree::DuplicateError
		end

#		it "raises an exception when a catalog is provided, but no callback is assigned" do
#			expect do
#				router.bind(manifest)
#			end.to raise_error
#		end

		it "expects callbacks if catalog resources exist" do
  		empty_manifest = Conf::Manifest.new(
        id: "com.stremio.addon.example-2",
        name: "DemoAddon",
        description: "An example stremio addon",
        version: "0.0.1")
			expect do
				router.bind(empty_manifest) { }
			end.to_not raise_error
			
		end
  end
end
