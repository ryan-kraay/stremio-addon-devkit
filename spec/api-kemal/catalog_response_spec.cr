require "./spec_helper"
require "../../src/stremio-addon-devkit/api/catalog_response"

Spectator.describe Stremio::Addon::DevKit::Api::CatalogResponse do
  alias Api = Stremio::Addon::DevKit::Api
  alias Conf = Stremio::Addon::DevKit::Conf

  subject {
      Api::CatalogResponse.build do |catalog|
        catalog.metas << Api::CatalogResponse::Meta.new(
            Conf::ContentType::Movie,
            "tt0032138",
            "The Wizard of Oz",
            URI.parse("https://images.metahub.space/poster/medium/tt0032138/img")
        )
        catalog.metas << Api::CatalogResponse::Meta.new(
            Conf::ContentType::Movie,
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
