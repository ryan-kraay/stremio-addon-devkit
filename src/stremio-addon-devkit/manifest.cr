require "json"
require "json-serializable-fake"

module Stremio::Addon::DevKit

  # This should be customized based on *your* addon
  #  See: https://github.com/Stremio/stremio-addon-sdk/blob/master/docs/api/responses/manifest.md#filtering-properties
  #
  # WARNING:  This **IS** case sensative and _should_ be lower-case
  enum ResourceType
    Catalog
    Meta
    Stream
    Subtitles
    Addon_catalog
  end

  # A Manifest consists of a collection of ResoruceType's
  #  Source: https://github.com/Stremio/stremio-addon-sdk/blob/master/docs/api/responses/manifest.md
  class Manifest(ResourceT, ContentT)
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

    @[JSON::FakeField]
    def catalogs(json : ::JSON::Builder) : Nil
      json.array do
        # TODO populate the catalogs here
      end
    end

    #@[JSON::FakeField]
    #def meta(json : ::JSON::Builder) : Nil
    #  # TODO:  See https://github.com/Stremio/stremio-addon-sdk/blob/master/docs/api/responses/meta.md
    #  # TODO:  See https://github.com/Stremio/stremio-addon-sdk/blob/master/docs/api/requests/defineMetaHandler.md
    #end

    #@[JSON::FakeField]
    #def streams(json : ::JSON::Builder) : Nil
    #  # TODO:  See https://github.com/Stremio/stremio-addon-sdk/blob/master/docs/api/responses/stream.md
    #end

    #@[JSON::FakeField]
    #def subtitles(json : ::JSON::Builder) : Nil
    #  # TOOD:  See https://github.com/Stremio/stremio-addon-sdk/blob/master/docs/api/responses/subtitles.md
    #end

    #@[JSON::FakeField]
    #def addonCatalogs(json : ::JSON::Builder) : Nil
    #  # TODO:  See https://github.com/Stremio/stremio-addon-sdk/blob/master/docs/api/responses/manifest.md#addon-catalogs
    #end


    @[JSON::FakeField]
    def resources(json : ::JSON::Builder) : Nil
      json.array do
        # TODO: if catalogs then ResourceType::Catalog.to_s.to_json
      end
    end

    @[JSON::FakeField]
    def types(json : ::JSON::Builder) : Nil
      json.array do
        # TODO: Iterate through everything (catalogs, etc) and put it into a set - use ContentType
      end
    end

    @[JSON::FakeField]
    def idPrefixes(json : ::JSON::Builder) : Nil
      json.array do
        # TODO: Iterate through everything that has idPrefixes and merge them into this list
      end
    end
  end

end

