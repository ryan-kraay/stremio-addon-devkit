require "./spec_helper"
require "../../src/stremio-addon-devkit/api/catalog_movie_request"

Spectator.describe Stremio::Addon::DevKit::Api::CatalogMovieRequest do
  alias CatalogMovieRequest = Stremio::Addon::DevKit::Api::CatalogMovieRequest
  alias Conf = Stremio::Addon::DevKit::Conf

  let(manifest) { Conf::Manifest.build(
    id: "com.stremio.addon.example",
    name: "DemoAddon",
    description: "An example stremio addon",
    version: "0.0.1") do |conf|
    conf << Conf::CatalogMovie.new(Conf::ContentType::Movie, "movie4u", "Movies for you")
  end }

  it "can be constructed" do
    expect do
      CatalogMovieRequest.new(manifest, manifest.catalog_movies[0])
    end.to_not raise_error
  end
end
