require "./spec_helper"
require "../../src/stremio-addon-devkit/catalog_movie_response"

Spectator.describe Stremio::Addon::DevKit::CatalogMovieResponse do
  alias DevKit = Stremio::Addon::DevKit

  subject {
    DevKit::CatalogMovieResponse.build do |catalog|
      catalog.metas << DevKit::CatalogMovieResponse::MetaPreview.new(
        "tt0032138",
        "The Wizard of Oz",
        URI.parse("https://images.metahub.space/poster/medium/tt0032138/img")
      )
      catalog.metas << DevKit::CatalogMovieResponse::MetaPreview.new(
        "tt0017136",
        "Metropolis",
        URI.parse("https://images.metahub.space/poster/medium/tt0017136/img"),
        ["Drama", "Sci-Fi"]
      )
    end
  }
  it "can be constructed" do
    expect do
      subject
    end.to_not raise_error
    expect(subject.metas.size).to eq(2)
  end
end
