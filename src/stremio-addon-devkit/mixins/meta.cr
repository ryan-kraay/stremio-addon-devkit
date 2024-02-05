require "json"
require "json-serializable-fake"
require "uri"
require "../content_type"


module Stremio::Addon::DevKit::Mixins

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

  enum LinkCategory
    Directors
    Writers
    Cast
  end

  module Meta
    include JSON::Serializable
    include JSON::Serializable::Fake

    # The `type` should match the catalog type.
    getter type : ContentType

    # You can use any unique string for the `id`.
    # In this case we use the corresponding IMDB ID.
    # Stremio features an system add-on called Cinemeta.
    # This add-on provides detailed metadata for any movie or
    # TV show that matches a valid IMDB ID.
    #
    # NOTE: All IMDB ID's begin with 'tt' (ie: tt0032138)
    property id : String

    # Depending on if it's MetaPreview or Meta, these fields
    # may or may not be optional
    # property name : String
    # property poster : URI

    enum PosterShape
      Square    # 1:1 aspect ratio
      Poster    # 1:0.675 aspect ratio (IMDb poster type)
      Landscape # 1:1.77 aspect ratio
    end
    property posterShape : PosterShape

    #### Additional Parameters that are used for the Discover Page Sidebar:

    # The `genre` is just a human-readable descriptive field
    # TODO: Instead of an Array(String) it should be a generic Array(Enum-of-Genres)
    @[JSON::Field(ignore: true)]
    property genre : Array(String)
    @[JSON::FakeField(suppress_key: true)]
    def genre(json : ::JSON::Builder) : Nil
      # We want `genre` to only appear, if the Array is non-empty
      genre.to_json json unless genre.empty?
    end

    class Link
      include JSON::Serializable

      # **required** - string, human readable name for the link
      property name : String

      # **required** - string, any unique category name, links are grouped based on their category, some recommended categories are: `actor`, `director`, `writer`, while the following categories are reserved and should not be used: `imdb`, `share`, `similar`
      property category : String

      # **required** - string, an external URL or [``Meta Link``](./meta.links.md)
      @[JSON::Field(converter: Stremio::Addon::DevKit::Mixins::URIConverter)]
      property url : URI
    end

    abstract class LinkSearchable < Link
      def initialize(@name)
        @url = URI.parse("stremio:///search?search=#{URI.encode_path_segment @name}")
      end
    end
    class LinkDirector < LinkSearchable
      @category = LinkCategory::Directors.to_s
    end
    class LinkWriter < LinkSearchable
      @category = LinkCategory::Writers.to_s
    end
    class LinkCast < LinkSearchable
      @category = LinkCategory::Cast.to_s
    end
    class LinkGenre < Link
      def initialize(@name)
        @category = "genres"
        @url = URI.parse("stremio:///discover/https%3A%2F%2Fv3-cinemeta.strem.io%2Fmanifest.json/movie/top?genre=#{@name}")
      end
    end

    @[JSON::Field(ignore: true)]
    property links : Array(Link)
    @[JSON::FakeField(suppress_key: true)]
    def links(json : ::JSON::Builder ) : Nil
      json.field "links" do
        @links.to_json json
      end unless @links.empty?
    end

    # ``director``, ``cast`` - _optional_  - directors and cast, both arrays of names (string) (warning: this will soon be deprecated in favor of ``links``)
    macro link_legacy(key, category)
      category = {{ category }}.to_s
      array_open : Bool = false

      begin
        @links.select do |link|
          # String comparisons are certainly slower than comparing enumeration
          # types, but the flexibility we gain by using strings will (hopefully)
          # make-up for it
          link.category == category
        end.each do |link|
          if array_open == false
            # We want to only show our field/array *if* there is a matching value
            json.string {{ key.id.stringify }}
            json.start_array
            array_open = true
          end
          link.name.to_json json
        end
      ensure
        if array_open
          json.end_array
        end
      end
    end
    @[JSON::FakeField(suppress_key: true)]
    def director(json : ::JSON::Builder ) : Nil
      link_legacy(:director, LinkCategory::Directors)
    end
    @[JSON::FakeField(suppress_key: true)]
    def writer(json : ::JSON::Builder ) : Nil
      link_legacy(:writer, LinkCategory::Writers)
    end
    @[JSON::FakeField(suppress_key: true)]
    def cast(json : ::JSON::Builder ) : Nil
      link_legacy(:cast, LinkCategory::Cast)
    end
  end
end
