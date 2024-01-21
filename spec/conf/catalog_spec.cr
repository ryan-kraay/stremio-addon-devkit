require "./spec_helper"
require "../../src/stremio-addon-devkit/conf/catalog"

Spectator.describe Stremio::Addon::DevKit::Conf::CatalogMovie do
  alias CatalogMovie = Stremio::Addon::DevKit::Conf::CatalogMovie
  alias ContentType = Stremio::Addon::DevKit::Conf::ContentType

  let(id) { "hello" }
  let(name) { "Hello Channel" }
  let(content_type) { ContentType::Movie }

  describe "ExtraSearch" do
    subject { CatalogMovie::ExtraSearch.new }

    it "can initialize" do
      expect do
        subject
      end.to_not raise_error
    end

    it "can initialize with isRequired" do
      is_required = true
      search = CatalogMovie::ExtraSearch.new(is_required)
      expect(search.name).to eq(CatalogMovie::ExtraType::Search)
      expect(search.isRequired).to eq(is_required)
    end

    it "can be a json string" do
      expect(subject.to_json).to eq({"name": "search", "isRequired": false}.to_json)
    end
  end

  describe "ExtraSkip" do
    subject { CatalogMovie::ExtraSkip.new }

    describe "#initialize" do
      it "can initialize" do
        expect do
          subject
        end.to_not raise_error
      end

      it "has sensible defaults" do
        expect(subject.name).to eq(CatalogMovie::ExtraType::Skip)
        expect(subject.isRequired).to be_false
        expect(subject.options).to be_nil
      end

      it "allows integer steps" do
        steps = [100_u32, 500_u32, 700_u32]
        string_steps = steps.map { |step| step.to_s }
        skip = CatalogMovie::ExtraSkip.new(steps: steps)
        expect(skip.options).to contain_exactly(*string_steps).in_order
      end

      it "allows custom steps" do
        # I have no idea why/how this is useful, but the sdk supports it
        steps = ["breakfast", "lunch", "dinner", "sleep"]
        skip = CatalogMovie::ExtraSkip.new(steps: steps)
        expect(skip.options).to contain_exactly(*steps).in_order
      end
    end

    it "can be a json string" do
      expect(subject.to_json).to eq({"name": "skip", "isRequired": false}.to_json)
    end
  end

  describe "ExtraGenre" do
    let(genres) { ["Action", "Comedy", "Sci-Fi"] }
    describe "#initialize" do
      it "accepts a list of genres" do
        result = CatalogMovie::ExtraGenre.new genres
        expect(result.to_json).to eq({"name": "genre", "isRequired": false, "optionsLimit": 1, "options": genres}.to_json)
      end
      it "accepts a block" do
        result = CatalogMovie::ExtraGenre.new do
          genres
        end
        expect(result.to_json).to eq({"name": "genre", "isRequired": false, "optionsLimit": 1, "options": genres}.to_json)
      end
      it "allows multiple genre's to be chosen" do
        max_selectable_genres = 2_u32
        result = CatalogMovie::ExtraGenre.new genres, max_selectable: max_selectable_genres
        expect(result.to_json).to eq({"name": "genre", "isRequired": false, "optionsLimit": max_selectable_genres, "options": genres}.to_json)
      end
    end
    describe "#to_json" do
      it "cannot have zero max_selectable_genres" do
        expect do
          CatalogMovie::ExtraGenre.new(genres, max_selectable: 0).to_json
        end.to raise_error(ArgumentError)
      end

      it "cannot have more selectable_genres than genres" do
        expect do
          CatalogMovie::ExtraGenre.new(genres, max_selectable: (genres.size + 1).to_u32).to_json
        end.to raise_error(ArgumentError)
      end

      it "cannot have empty genres" do
        expect do
          CatalogMovie::ExtraGenre.new(Array(String).new).to_json
        end.to raise_error(ArgumentError)
      end

      it "allows max_selectable to include all our genres" do
        expect do
          CatalogMovie::ExtraGenre.new(genres, max_selectable: genres.size.to_u32).to_json
        end.to_not raise_error
      end

      it "executes &block only when #to_json is called" do
        called = 0
        result = CatalogMovie::ExtraGenre.new do
          called += 1
          genres
        end

        expect(called).to eq(0)

        max_iteration = 2
        (1..max_iteration).each do |x|
          expect do
            result.to_json
          end.to_not raise_error
          expect(called).to eq(x)
        end

        # Just double check that we don't have a bug in our loop
        expect(called).to eq(max_iteration)
      end
    end
  end

  describe "#class" do
    let(genres) { ["Action", "Comedy", "Sci-Fi"] }
    let(skip) { CatalogMovie::ExtraSkip.new }
    let(search) { CatalogMovie::ExtraSearch.new }
    let(genre) { CatalogMovie::ExtraGenre.new genres }

    subject(catalog_extra) { CatalogMovie.new(id, name, skip, genre, search) }
    subject(catalog) { CatalogMovie.new(id, name) }
    describe "#initialize" do
      it "can initialize" do
        expect do
          catalog
        end.to_not raise_error
      end
    end

    it "can be converted to json" do
      expect(catalog.to_json).to eq({"type": content_type.to_s.downcase, "id": id, "name": name, "extra": Array(String).new}.to_json)
    end
    it "can convert #extra into json" do
      expected = {
        "type":  content_type.to_s.downcase,
        "id":    id,
        "name":  name,
        "extra": [
          {"name": "skip", "isRequired": false},
          {"name": "genre", "isRequired": false, "optionsLimit": 1, "options": genres},
          {"name": "search", "isRequired": false},
        ],
      }.to_json

      expect(catalog_extra.to_json).to eq(expected)
    end

    it "has proper getters" do
      expect(catalog.type).to eq(content_type)
      expect(catalog.id).to eq(id)
      expect(catalog.name).to eq(name)
    end
  end
end
