require "./spec_helper"
require "../../src/stremio-addon-devkit/catalog_movie_request"

Spectator.describe Stremio::Addon::DevKit::CatalogMovieRequest do
  alias CatalogMovieRequest = Stremio::Addon::DevKit::CatalogMovieRequest
  alias DevKit = Stremio::Addon::DevKit

  let(manifest) { DevKit::Manifest.build(
    id: "com.stremio.addon.example",
    name: "DemoAddon",
    description: "An example stremio addon",
    version: "0.0.1") do |conf|
    conf << DevKit::CatalogMovie.new("movie4u", "Movies for you")
  end }

  it "can be constructed" do
    expect do
      CatalogMovieRequest.new(manifest, manifest.catalog_movies[0])
    end.to_not raise_error
  end
end
