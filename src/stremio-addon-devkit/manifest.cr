require "json"
require "json-serializable-fake"
require "./catalog"
require "./resource_type"

module Stremio::Addon::DevKit
  # Represents a single entry in the "resources: []" described in the manifest.json
  #
  # There is a more condensed form of this (ie: `resources: ["catalog"]`).  However, we also use this more
  # verbose form to generate the `types: []` entry in the manifest.json.
  #
  # source: https://github.com/Stremio/stremio-addon-sdk/blob/master/docs/api/responses/manifest.md#advanced
  @[JSON::Serializable::Options(ignore_deserialize: true)]
  class ManifestResource
    include JSON::Serializable
    include JSON::Serializable::Fake

    # `name`: **required** - string, the name of the resource
    getter name : ResourceType
    # `types`: **required** - array of strings, supported types, from all the [Content Types](https://github.com/Stremio/stremio-addon-sdk/blob/master/docs/api/responses/content.types.md)
    property types : Set(ContentType)
    # `idPrefixes`: **optional** - array of strings, use this if you want your addon to be called only for specific content IDs - for example, if you set this to `["yt_id:", "tt"]`, your addon will only be called for id values that start with `yt_id:` or `tt`.
    # NOTE:  This is only relevant for resource_types of `stream` and `meta`.  This should **not** be used for `catalog` resources.
    @[JSON::Field(ignore: true)] # we will render idPrefixes via JSON::FakeField
    property idPrefixes : Set(String)

    @[JSON::FakeField(suppress_key: true)]
    def idPrefixes(json : ::JSON::Builder) : Nil
      # We want idPrefixes to only appear, if the Set is non-empty
      idPrefixes.to_json json unless idPrefixes.empty?
    end

    def initialize(@name : ResourceType, @types = Set(ContentType).new, @idPrefixes = Set(String).new)
    end
  end

  def self.asResource(manifest_resource, iterable : Array(T)) : Nil forall T
    iterable.each do |thing|
      thing.insert_resource(manifest_resource)
    end
  end

  # A Manifest consists of a collection of ResourceTypes
  #  Source: https://github.com/Stremio/stremio-addon-sdk/blob/master/docs/api/responses/manifest.md
  class Manifest
    include JSON::Serializable
    include JSON::Serializable::Fake

    # `id`:  **required** - string, identifier, dot-separated, e.g. "com.stremio.filmon"
    getter id : String
    # `name`: **required** - string, human readable name
    getter name : String
    # `description`: **required** - string, human readable description
    getter description : String
    # `version`: **required** - string, [semantic version](https://semver.org/) of the addon
    getter version : String
    # `logo`: **optional** - string, a url to a small logo to use in stremio (ie: https://www.stremio.com/website/stremio-logo-small.png)
    getter logo : String?

    # @[JSON::FakeField]
    # def meta(json : ::JSON::Builder) : Nil
    #  # TODO:  See https://github.com/Stremio/stremio-addon-sdk/blob/master/docs/api/responses/meta.md
    #  # TODO:  See https://github.com/Stremio/stremio-addon-sdk/blob/master/docs/api/requests/defineMetaHandler.md
    # end

    # @[JSON::FakeField]
    # def streams(json : ::JSON::Builder) : Nil
    #  # TODO:  See https://github.com/Stremio/stremio-addon-sdk/blob/master/docs/api/responses/stream.md
    # end

    # @[JSON::FakeField]
    # def subtitles(json : ::JSON::Builder) : Nil
    #  # TOOD:  See https://github.com/Stremio/stremio-addon-sdk/blob/master/docs/api/responses/subtitles.md
    # end

    # @[JSON::FakeField]
    # def addonCatalogMovies(json : ::JSON::Builder) : Nil
    #  # TODO:  See https://github.com/Stremio/stremio-addon-sdk/blob/master/docs/api/responses/manifest.md#addon-catalogs
    # end

    #
    # Catalog
    #

    # expanded macro magic
    @[JSON::Field(ignore: true)]
    property catalog_movies = [] of CatalogMovie

    def each_catalog(&block)
      catalog_movies.each do |movie|
        yield movie
      end
    end

    def <<(x : CatalogMovie) : self
      catalog_movies << x
      self
    end

    @[JSON::FakeField]
    def catalogs(json : ::JSON::Builder) : Nil
      json.array do
        each_catalog do |catalog|
          catalog.to_json json
        end
      end
    end

    #
    # Resource
    #
    def resources : Array(ManifestResource)
      result = [] of ManifestResource

      resource = ManifestResource.new ResourceType::Catalog
      each_catalog do |catalog|
        resource.types << catalog.type
      end
      result << resource unless resource.types.empty?

      result
    end

    @[JSON::FakeField]
    def resources(json : ::JSON::Builder) : Nil
      resources.to_json json
    end

    def types : Set(ContentType)
      type_set = Set(ContentType).new

      resources.each do |resource|
        type_set.concat resource.types
      end

      type_set
    end

    @[JSON::FakeField]
    def types(json : ::JSON::Builder) : Nil
      types.to_json json
    end

    #
    # idPrefixes
    #

    @[JSON::FakeField]
    def idPrefixes(json : ::JSON::Builder) : Nil
      json.array do
        # TODO: Iterate through everything that has idPrefixes and merge them into this list
      end
    end

    def initialize(@id, @name, @description, @version, @logo = nil)
    end

    # A static function call to inline the complete construction
    # of a manifest object.
    #
    # Example:
    # ```
    # manifest = Manifest(ContentType).build(
    #   id: "com.stremio.addon.example",
    #   name: "DemoAddon",
    #   description: "An example stremio addon",
    #   version: "0.0.1") do |conf|
    #   conf << CatalogMovie.new(ContentType::Movie, "movie4u", "Movies for you")
    # end
    # ```
    #
    # TODO:  Should this be moved into the macro?  As a method on .new()?
    def self.build(*args, **named_args, &)
      manifest = Manifest.new(*args, **named_args)
      yield manifest
      return manifest
    end
  end
end
