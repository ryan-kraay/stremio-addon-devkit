require "json"
require "json-serializable-fake"
require "uri"
require "../conf/content_type"

module Stremio::Addon::DevKit::Api
  # Represents a valid catalog.json response
  # source: https://stremio.github.io/stremio-addon-guide/step3
  # source: https://github.com/Stremio/stremio-addon-sdk/blob/master/docs/api/responses/meta.md
  # @[JSON::Serializable::Options(ignore_deserialize: true)]
  class CatalogMovieResponse
    include JSON::Serializable
    alias Conf = Stremio::Addon::DevKit::Conf

    class Meta
      include JSON::Serializable
      include JSON::Serializable::Fake

      # The `type` should match the catalog type.
      property type : Conf::ContentType

      # You can use any unique string for the `id`.
      # In this case we use the corresponding IMDB ID.
      # Stremio features an system add-on called Cinemeta.
      # This add-on provides detailed metadata for any movie or
      # TV show that matches a valid IMDB ID.
      #
      # NOTE: All IMDB ID's begin with 'tt' (ie: tt0032138)
      id : String

      # The `name` is just a human-readable descriptive field
      property name : String?

      # Stremio's catalog consists of grid of images, fetched from
      # the `poster` field of every item. It should be a
      # valid URL to an image.
      @[JSON::Field(converter: Stremio::Addon::DevKit::Api::CatalogMovieResponse::Meta::URIConverter)]
      property poster : URI?

      # The `genre` is just a human-readable descriptive field
      # TODO: Instead of an Array(String) it should be a generic Array(Enum-of-Genres)
      @[JSON::Field(ignore: true)]
      property genre : Array(String)
      @[JSON::FakeField(suppress_key: true)]
      def genre(json : ::JSON::Builder) : Nil
        # We want `genre` to only appear, if the Array is non-empty
        genre.to_json json unless genre.empty?
      end

      def initialize(@type : Conf::ContentType, @id : String, @name : String?, @poster : URI?, @genre = Array(String).new)
      end

      # Adds custom handling of the to/from json for URI objects
      module URIConverter
        def self.to_json(uri : URI, json : JSON::Builder) : Nil
          json.string(uri.to_s)
        end

        # def self.from_json(value : JSON::PullParser) : URI
        #  # TODO fix URI parse syntax to parse a string
        #  URI.parse(value.string)
        # end
      end
    end

    property metas : Array(Meta)

    def initialize(@metas = Array(Meta).new)
    end

    def self.build(&block)
      result = CatalogMovieResponse.new
      yield result
      result
    end
  end
end
