require "json"
require "json-serializable-fake"
require "./mixins/meta"

module Stremio::Addon::DevKit
  # Represents a valid catalog.json response
  # source: https://stremio.github.io/stremio-addon-guide/step3
  # source: https://github.com/Stremio/stremio-addon-sdk/blob/master/docs/api/responses/meta.md
  # @[JSON::Serializable::Options(ignore_deserialize: true)]
  class CatalogMovieResponse
    include JSON::Serializable
    alias Conf = Stremio::Addon::DevKit

    # This is a shorter variant of the Meta Object
    # source: stremio-addon-sdk/docs/api/responses/meta.md
    class MetaPreview
      include Mixins::Meta

      def self.build(*args, **named_args, &)
        matapreview = MetaPreview.new(*args, **named_args)
        yield matapreview
        return matapreview
      end

      # The `name` is just a human-readable descriptive field
      property name : String

      # Stremio's catalog consists of grid of images, fetched from
      # the `poster` field of every item. It should be a
      # valid URL to an image.
      @[JSON::Field(converter: Stremio::Addon::DevKit::Mixins::URIConverter)]
      property poster : URI

      def initialize(@id : String, @name : String, @poster : URI, @posterShape = PosterShape::Poster)
        @genre = Array(String).new
        @type = ContentType::Movie
        @links = Array(Link).new
      end
    end

    property metas : Array(MetaPreview)

    def initialize(@metas = Array(MetaPreview).new)
    end

    def self.build(&block)
      result = CatalogMovieResponse.new
      yield result
      result
    end
  end
end
