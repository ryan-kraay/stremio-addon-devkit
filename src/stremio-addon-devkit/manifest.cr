require "json"
require "json-serializable-fake"

module Stremio::Addon::DevKit
  # This should be customized based on *your* addon
  #  See: https://github.com/Stremio/stremio-addon-sdk/blob/master/docs/api/responses/manifest.md#filtering-properties
  #
  # WARNING:  This **IS** case sensative and _should_ be lower-case
  # NOTE:  These values **must** correspond to the names used in the url (ie: /<userdata>/meta/<content-type>/..., /catalog/<content-type>/...)
  enum ResourceType
    Catalog
    #    Meta # confirmed
    #    Stream # confirmed
    #    Subtitles
    #    Addon_catalog
  end

  # Represents a single entry in the "resources: []" described in the manifest.json
  #
  # There is a more condensed form of this (ie: `resources: ["catalog"]`).  However, we also use this more
  # verbose form to generate the `types: []` entry in the manifest.json.
  #
  # source: https://github.com/Stremio/stremio-addon-sdk/blob/master/docs/api/responses/manifest.md#advanced
  @[JSON::Serializable::Options(ignore_deserialize: true)]
  class ManifestResource(ContentT, ResourceT)
    include JSON::Serializable
    include JSON::Serializable::Fake

    # `name`: **required** - string, the name of the resource
    getter name : ResourceT
    # `types`: **required** - array of strings, supported types, from all the [Content Types](https://github.com/Stremio/stremio-addon-sdk/blob/master/docs/api/responses/content.types.md)
    property types : Set(ContentT)
    # `idPrefixes`: **optional** - array of strings, use this if you want your addon to be called only for specific content IDs - for example, if you set this to `["yt_id:", "tt"]`, your addon will only be called for id values that start with `yt_id:` or `tt`.
    # NOTE:  This is only relevant for resource_types of `stream` and `meta`.  This should **not** be used for `catalog` resources.
    @[JSON::Field(ignore: true)] # we will render idPrefixes via JSON::FakeField
    property idPrefixes : Set(String)

    @[JSON::FakeField(suppress_key: true)]
    def idPrefixes(json : ::JSON::Builder) : Nil
      # We want idPrefixes to only appear, if the Set is non-empty
      idPrefixes.to_json json unless idPrefixes.empty?
    end

    def initialize(@name : ResourceT, @types = Set(ContentT).new, @idPrefixes = Set(String).new)
    end
  end

  def self.asResource(manifest_resource, iterable : Array(T)) : Nil forall T
    iterable.each do |thing|
      thing.insert_resource(manifest_resource)
    end
  end

  # A Manifest consists of a collection of ResourceTypes
  #  Source: https://github.com/Stremio/stremio-addon-sdk/blob/master/docs/api/responses/manifest.md
  class ManifestBase
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

    # This is the glue that binds a manifest:
    #   1. To a ResourceType (ie: meta, catalog, etc)
    #   2. To a ContentType (ie: movie, series, tv, etc)
    #   3. To an class/implementation (ie: ::Catalog(ContentType).new)
    #
    # This macro does a lot of magic in an attempt to normalize some of the irregularies in
    #  the stremio manifest (ie: the use of "catalog" everywhere, except in the root of the manifest, where it's "catalogs".
    #  Except for "subtitles", which is "subtitles" everywhere... and "meta" which only appears as a "resources" entry))
    #
    # URL's take the form of: https://you.domain/<userdata?>/<resource_type>/<content_type>/<content-specific-data/...
    #
    # Due to these edge-cases, we've created the following
    # TODO: {
    #        "name": "meta",
    #        "types": ["movie"],
    #        "idPrefixes": ["hiwrld_"]
    #    }
    #
    macro bind_resources(resource_type, content_type, list)
      {% properties = {} of Nil => Nil %}
      {% for ann in list %}
        {% unless ann[:ignore] %}
          {% plural_form = ((ann && ann[:plural_name]) || "#{ann[:enum].names[-1].id}s".downcase) %}
          {%
            properties[ann[:enum].id] = {
              plural_name:   plural_form.stringify,
              property_name: ((ann && ann[:property_name]) || plural_form).id,
              class:         ann[:as],
            }
          %}
        {% end %}
      {% end %}

      {% for resource_enum, prop in properties %}
        property {{ prop[:property_name] }} = [] of {{ prop[:class] }}
      {% end %}

      def resources() : Array(ManifestResource( {{ content_type }}, {{ resource_type }} ))
        result = [] of ManifestResource( {{ content_type }}, {{ resource_type }} )

        {% for resource_enum, prop in properties %}
          manifest_resource = ManifestResource( {{ content_type }}, {{ resource_type }} ).new {{ resource_enum }}
          ::Stremio::Addon::DevKit.asResource(manifest_resource, {{ prop[:property_name] }} )
          # manifest_resource.types **cannot** be empty, unless we don't have any prop[:property_name]... hence we check if idPrefixes has content.
          # if it has content, this means it's a bug in asResource().  If it's empty, it simply means we don't have any of this type
          raise ArgumentError.new("ManifestResource types:[] for {{ prop[:property_name] }} cannot be empty") if manifest_resource.types.empty? && !manifest_resource.idPrefixes.empty?
          result << manifest_resource unless manifest_resource.types.empty?
        {% end %}

        result
      end

      @[JSON::FakeField]
      def resources(json : ::JSON::Builder) : Nil
        resources.to_json json
      end

      @[JSON::FakeField]
      def types(json : ::JSON::Builder) : Nil
        # Iterate through all resource_types and get the content_type
        type_set = Set( {{ content_type }} ).new

        resources.each do |resource|
          type_set.concat resource.types
        end

        type_set.to_json json
      end
    end

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
    # def addonCatalogs(json : ::JSON::Builder) : Nil
    #  # TODO:  See https://github.com/Stremio/stremio-addon-sdk/blob/master/docs/api/responses/manifest.md#addon-catalogs
    # end

    @[JSON::FakeField]
    def idPrefixes(json : ::JSON::Builder) : Nil
      json.array do
        # TODO: Iterate through everything that has idPrefixes and merge them into this list
      end
    end

    def initialize(@id, @name, @description, @version, @logo = nil)
    end
  end

  class Manifest(ContentT) < ManifestBase
    bind_resources(ResourceType, ContentT, [{enum: ResourceType::Catalog, as: Catalog(ContentT)}])
  end
end
