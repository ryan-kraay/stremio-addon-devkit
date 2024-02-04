require "./spec_helper"
# stremio-addon-devkit/api should include everything to construct
#  stremio api (as a side-effect it may include most of stremio-addon-devkit/conf)
require "../../src/stremio-addon-devkit/api"

Kemal.run

Spectator.describe Stremio::Addon::DevKit::ManifestHandler do
  alias DevKit = Stremio::Addon::DevKit

  let(manifest) { DevKit::Manifest.build(
    id: "com.stremio.addon.example",
    name: "DemoAddon",
    description: "An example stremio addon",
    version: "0.0.1") do |conf|
    conf << DevKit::CatalogMovie.new(
      id: "movie4u",
      name: "Movies for you")
  end }

  let(router) { DevKit::ManifestHandler.new }
  before_each do
    reset_kemal do
      add_handler router
    end
  end

  describe "#route_manifest" do
    let(manifest) { DevKit::Manifest.build(
      id: "com.stremio.addon.example",
      name: "DemoAddon",
      description: "An example stremio addon",
      version: "0.0.1") do |conf|
    end }
    let(url) { "/manifest.json" }

    it "executes a proc when accessing a manifest endpoint" do
      accessed = false
      handler = ->(env : HTTP::Server::Context, manifest : DevKit::ManifestRequest) {
        accessed = true
        nil
      }
      router.route_manifest(manifest, &handler)

      get url
      expect(response.status_code).to eq(200)
      expect(accessed).to eq true
    end

    it "provides a valid response" do
      router.bind(manifest) do |callback|
        # We'll use the default manifest callback
      end

      get url
      expect(response.status_code).to eq(200)
      expect(response.body).to eq(manifest.to_json)
      expect(response.content_type).to eq("application/json")
      expect(response.charset).to eq("utf-8")
      expect(response.headers["access-control-allow-origin"]).to eq("*")
    end
  end

  describe "#route_catalogs" do
    it "executes a proc when accessing a catalog endpoint" do
      accessed = false
      handler = ->(env : HTTP::Server::Context, addon : DevKit::CatalogMovieRequest) {
        accessed = true
        nil
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
        nil
      end

      get "/catalog/movie/movie4u.json"
      expect(response.status_code).to eq(200)
      expect(accessed).to eq true
    end

    it "redirects url encoded content to non-url encoded content" do
      # There appears to be a bug with Android TV versions of stremio, as catalog id's will be url encoded (with upper case characters)
      catalog_id = "movie-4u"
      expected_destination = "/catalog/movie/#{catalog_id}.json"
      expected_url = "/catalog/movie/movie%2D4u.json"
      manifest = DevKit::Manifest.build(
        id: "com.stremio.addon.example",
        name: "DemoAddon",
        description: "An example stremio addon",
        version: "0.0.1") do |conf|
        conf << DevKit::CatalogMovie.new(
          id: catalog_id,
          name: "Movies for you")
      end
      router.bind(manifest) do |callback|
        callback.catalog_movie { nil }
      end

      expect do
        get expected_url
      end.to_not raise_error Kemal::Exceptions::RouteNotFound
      expect(response.status_code).to eq(301)
      expect(response.headers["location"]).to eq(expected_destination)
    end

    it "converts a CatalogMovieResponse object into a valid http response" do
      router.route_catalogs(manifest) do |env, addon|
        DevKit::CatalogMovieResponse.build do |catalog|
          catalog.metas << DevKit::CatalogMovieResponse::MetaPreview.new(
            "tt0032138",
            "The Wizard of Oz",
            URI.parse("https://images.metahub.space/poster/medium/tt0032138/img")
          )
        end
      end

      get "/catalog/movie/movie4u.json"
      expect(response.status_code).to eq(200)
      expect(response.content_type).to eq("application/json")
      expect(response.charset).to eq("utf-8")
      expect(response.headers["access-control-allow-origin"]).to eq("*")
      expect(response.body).to eq({"metas": [{"type": "movie",
                                              "name": "The Wizard of Oz", "poster": "https://images.metahub.space/poster/medium/tt0032138/img", "id": "tt0032138"}]}.to_json)
    end
  end

  describe "#bind" do
    it "binds a manifest to a callback" do
      accessed = false
      my_catalog_handler = ->(env : HTTP::Server::Context, addon : DevKit::CatalogMovieRequest) {
        accessed = true
        nil
      }

      router.bind(manifest) do |callback|
        callback.catalog_movie &my_catalog_handler
      end

      get "/catalog/movie/movie4u.json"
      expect(response.status.code).to eq(200)
      expect(accessed).to eq true
    end

    it "does not allow the same manifest to be rebounded" do
      my_catalog_handler = ->(env : HTTP::Server::Context, addon : DevKit::CatalogMovieRequest) { nil }

      # The first invocation should create all the necessary routes
      expect do
        router.bind(manifest) do |callback|
          callback.catalog_movie &my_catalog_handler
        end
      end.to_not raise_error

      # Second invocation will complain that the routes already exist
      expect do
        router.bind(manifest) do |callback|
          callback.catalog_movie &my_catalog_handler
        end
      end.to raise_error Radix::Tree::DuplicateError
    end

    it "raises an exception when a catalog is provided, but no callback is assigned" do
      expect do
        router.bind(manifest) { }
      end.to raise_error DevKit::ManifestBindingError
    end

    it "expects callbacks if catalog resources exist" do
      empty_manifest = DevKit::Manifest.new(
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
