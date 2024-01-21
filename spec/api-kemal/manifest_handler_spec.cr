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
    conf << Conf::CatalogMovie.new(
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

  describe "#route_manifest" do
    let(manifest) { Conf::Manifest.build(
      id: "com.stremio.addon.example",
      name: "DemoAddon",
      description: "An example stremio addon",
      version: "0.0.1") do |conf|
    end }
    let(url) { "/manifest.json" }

    it "executes a proc when accessing a manifest endpoint" do
      accessed = false
      handler = ->(env : HTTP::Server::Context, manifest : Api::ManifestRequest) {
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
      handler = ->(env : HTTP::Server::Context, addon : Api::CatalogMovieRequest) {
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
      manifest = Conf::Manifest.build(
        id: "com.stremio.addon.example",
        name: "DemoAddon",
        description: "An example stremio addon",
        version: "0.0.1") do |conf|
        conf << Conf::CatalogMovie.new(
          type: Conf::ContentType::Movie,
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
        Api::CatalogMovieResponse.build do |catalog|
          catalog.metas << Api::CatalogMovieResponse::Meta.new(
            Conf::ContentType::Movie,
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
      my_catalog_handler = ->(env : HTTP::Server::Context, addon : Api::CatalogMovieRequest) {
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
      my_catalog_handler = ->(env : HTTP::Server::Context, addon : Api::CatalogMovieRequest) { nil }

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
      end.to raise_error Api::ManifestBindingError
    end

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
