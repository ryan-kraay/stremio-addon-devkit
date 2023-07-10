require "json"
require "json-serializable-fake"

module Stremio::Addon::DevKit
  # These are the possible content types supported by Stremio, you can prune or expand this to fit your needs
  #  See: https://github.com/Stremio/stremio-addon-sdk/blob/master/docs/api/responses/content.types.md
  enum ContentType
    # `movie`: movie has metadata like name, genre, description, director, actors, images, etc.
    Movie
    # `series`: has all the metadata a movie has, plus an array of episodes
    Series
    # `channel`: created to cover YouTube channels; has name, description and an array of uploaded videos
    Channel
    # `tv`: has name, description, genre; streams for tv should be live (without duration)
    TV
  end

  @[JSON::Serializable::Options(ignore_deserialize: true)]
  class Catalog(ContentT)
    include JSON::Serializable
    include JSON::Serializable::Fake

    # Catalogs support an (optional) Extra field.
    #   source: https://github.com/Stremio/stremio-addon-sdk/blob/master/docs/api/requests/defineCatalogHandler.md#extra-parameters
    enum ExtraType
      # `search`: The Catalog can be searched
      Search
      # `genre`: The Catalog can be filtered by genres
      Genre
      # `skip`: The Catalog supports pagination
      Skip
    end

    # Allows this catalog have content filtered based on user search parameters
    @[JSON::Serializable::Options(ignore_deserialize: true)]
    class ExtraSearch
      include JSON::Serializable

      # `name`: required - **string**, is the name of the property; this name will be used in the extraProps argument itself
      getter name : ExtraType
      # `isRequired`: optional - boolean, set to true if this property must always be passed
      getter isRequired : Bool

      def initialize(@isRequired = false)
        @name = ExtraType::Search
      end
    end

    # Enables Pagination
    #  See: https://github.com/Stremio/stremio-addon-sdk/blob/master/docs/advanced.md#pagination-in-catalogs
    @[JSON::Serializable::Options(ignore_deserialize: true)]
    class ExtraSkip
      include JSON::Serializable
      include JSON::Serializable::Fake

      # `name`: required - **string**, is the name of the property; this name will be used in the extraProps argument itself
      getter name : ExtraType
      # `isRequired`: optional - boolean, set to true if this property must always be passed
      getter isRequired : Bool

      # `options`: optional - an explicit lists of "steps" to follow.  If an empty list is defined, the default value of "100" will be used.
      # This means the addon will request 100 entries, until it receives less than 100 entries (to signify the end of the list)
      getter options : Array(String)?

      def initialize(@isRequired = false, steps = Array(UInt32).new)
        @name = ExtraType::Skip
        @options = steps.empty? ? nil : steps.map { |step| step.to_s }
      end
    end

    # `type`: **required** - string, this is the content type of the catalog
    getter type : ContentT
    # `id`: **required** - string, the id of the catalog, can be any unique string describing the catalog (unique per addon, as an addon can have many catalogs), for example: if the catalog name is "Favourite Youtube Videos", the id can be "fav_youtube_videos"
    getter id : String
    # `name`: **required** - string, human readable name of the catalog
    getter name : String

    def initialize(@type, @id, @name)
    end
  end
end
