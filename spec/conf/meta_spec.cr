require "./spec_helper"
require "../../src/stremio-addon-devkit/catalog_movie_response"

Spectator.describe Stremio::Addon::DevKit::CatalogMoiveResponse::MetaPreview do

  alias Meta = Stremio::Addon::DevKit::CatalogMovieResponse::MetaPreview
  alias ContentType = Stremio::Addon::DevKit::ContentType

  describe "::LinkDirector" do
    let(expected_director) { "Christopher Nolan" }
    let(expected_url) { "stremio:///search?search=Christopher%20Nolan" }
    let(expected_category) { "Directors" }
    subject { Meta::LinkDirector.new(expected_director) }

    it "generates proper parameters" do
      expect(subject.name).to eq expected_director
      expect(subject.category).to eq expected_category
      expect(subject.url).to eq URI.parse(expected_url)
    end

    it "generates json" do
      expect(subject.to_json).to eq({"name": expected_director, "category": expected_category, "url": expected_url}.to_json)
    end

    it "populates Meta#director" do
      sub = Meta.build(id: "tt15398776",
                name: "Oppenheimer",
                poster: URI.parse("https://127.0.0.1/example.png")) do |meta|
              meta.links << subject
            end

      sub_json = String.new()
      expect do
        sub_json = sub.to_json
      end.to_not raise_error

      result = JSON.parse(sub_json)
      key = "director"

      expect(result[key]?).to_not be_nil
      expect(result[key].as_a).to contain_exactly(expected_director).in_order
    end
  end

  describe "::LinkGenre" do
    let(expected_genre) { "History" }
    let(expected_category) { "Genres" }
    let(expected_url) { "stremio:///discover/https%3A%2F%2Fv3-cinemeta.strem.io%2Fmanifest.json/movie/top?genre=History" }
    subject { Meta::LinkGenre.new(expected_genre, ContentType::Movie, "top",  URI.parse("https://v3-cinemeta.strem.io/manifest.json")) }

    it "generates proper parameters" do
      expect(subject.name).to eq expected_genre
      expect(subject.category).to eq expected_category
      expect(subject.url).to eq URI.parse(expected_url)
    end

    it "generates json" do
      expect(subject.to_json).to eq({"name": expected_genre, "category": expected_category, "url": expected_url}.to_json)
    end

    it "populates Meta#genre" do
      sub = Meta.build(id: "tt15398776",
                name: "Oppenheimer",
                poster: URI.parse("https://127.0.0.1/example.png")) do |meta|
              meta.links << subject
            end

      sub_json = String.new()
      expect do
        sub_json = sub.to_json
      end.to_not raise_error

      result = JSON.parse(sub_json)

      # cinemeta returns both genre[] and genres[] -- it's unclear why
      # but the documentation clearly says "genre" is used
      expect(result["genre"]?).to_not be_nil
      expect(result["genre"].as_a).to contain_exactly(expected_genre).in_order
    end

  end

end
