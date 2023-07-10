require "./spec_helper"
require "../src/stremio-addon-devkit/catalog"

Spectator.describe Stremio::Addon::DevKit::Catalog do
  alias Catalog = Stremio::Addon::DevKit::Catalog
  alias ContentType = Stremio::Addon::DevKit::ContentType

  subject { Catalog.new(ContentType::Movie, "hello", "Hello Channel") }

  describe "ExtraSearch" do
    #subject { Stremio::Addon::DevKit::Catalog(ContentType)::ExtraSearch.new() }
    subject { Catalog::ExtraSearch.new() }

    it "can initialize" do
      expect do
        subject
      end.to_not raise_error
    end

    it "can initialize with isRequired" do
      is_required = true
      search = Catalog::ExtraSearch.new(is_required)
      expect(search.name).to eq(Catalog::ExtraType::Search)
      expect(search.isRequired).to eq(is_required)
    end

    it "can be a json string" do
      expect(subject.to_json).to eq( { "name": "search", "isRequired": false }.to_json )
    end
  end

  describe "ExtraSkip" do
    subject { Catalog::ExtraSkip.new() }

    describe "#initialize" do
      it "can initialize" do
        expect do
          subject
        end.to_not raise_error
      end

      it "has sensible defaults" do
        expect(subject.name).to eq(Catalog::ExtraType::Skip)
        expect(subject.isRequired).to be_false
        expect(subject.options).to be_nil
      end

      it "allows integer steps" do
        steps = [100_u32, 500_u32, 700_u32]
        string_steps = steps.map { |step| step.to_s }
        skip = Catalog::ExtraSkip.new(steps: steps)
        expect(skip.options).to contain_exactly( *string_steps ).in_order
      end

      it "allows custom steps" do
        # I have no idea why/how this is useful, but the sdk supports it
        steps = ["breakfast", "lunch", "dinner", "sleep"]
        skip = Catalog::ExtraSkip.new(steps: steps)
        expect(skip.options).to contain_exactly( *steps ).in_order
      end
    end

    it "can be a json string" do
      expect(subject.to_json).to eq( { "name": "skip", "isRequired": false }.to_json )
    end
  end

  describe "#initialize" do
    it "can initialize" do
      expect do
        subject
      end.to_not raise_error
    end
  end
end
