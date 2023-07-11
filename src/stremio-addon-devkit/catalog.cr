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

    # Enables Filtering Based on Genre *or other tags*
    #  See: https://github.com/Stremio/stremio-addon-sdk/blob/master/docs/api/responses/manifest.md#extra-properties
    @[JSON::Serializable::Options(ignore_deserialize: true)]
    class ExtraGenre
      include JSON::Serializable
      include JSON::Serializable::Fake
      alias GenresResultType = Array(String)
      alias GenresProcType = Proc(GenresResultType)

      # `name`: required - **string**, is the name of the property; this name will be used in the extraProps argument itself
      getter name : ExtraType
      # `isRequired`: optional - boolean, set to true if this property must always be passed
      getter isRequired : Bool

      # `optionsLimit` - optional - number, the limit of values a user may select from the pre-set options list; by default, this is set to 1
      getter optionsLimit : UInt32

      # `options`: optional - array of strings, possible values for this property; this is useful for things like genres, where you need the user to select from a pre-set list of options (e.g. { name: "genre", options: ["Action", "Comedy", "Drama"] });
      @[JSON::FakeField]
      def options(json : ::JSON::Builder) : Nil
        # normalize our genres as a simple Array of Strings
        g : GenresResultType = genres.is_a?(GenresProcType) ? genres.as(GenresProcType).call : genres.as(GenresResultType)

        raise ArgumentError.new("ExtraGenre#max_selectable cannot be 0") unless @optionsLimit > 0_u32
        raise ArgumentError.new("ExtraGenre@max_selectable cannot be larger than the number of genres(#{g.size})") if @optionsLimit > g.size

        g.to_json(json)
      end

      # `genres` - **required** a list of genres or other tags that the user can filter/select from
      # **NOTE**:  The list of genres is only generated when creating a manfiest.  Afterwards, this list of genres cannot be changed (unless the addon is
      #  reinstalled)
      @[JSON::Field(ignore: true)]
      getter genres : GenresResultType | GenresProcType

      def initialize(@genres : GenresResultType | GenresProcType, @isRequired = false, max_selectable : UInt32 = 1)
        @name = ExtraType::Genre
        @optionsLimit = max_selectable
      end

      def initialize(isRequired = false, max_selectable : UInt32 = 1, &block : -> GenresResultType)
        initialize(block, isRequired, max_selectable)
      end
    end

    # `type`: **required** - string, this is the content type of the catalog
    getter type : ContentT
    # `id`: **required** - string, the id of the catalog, can be any unique string describing the catalog (unique per addon, as an addon can have many catalogs), for example: if the catalog name is "Favourite Youtube Videos", the id can be "fav_youtube_videos"
    getter id : String
    # `name`: **required** - string, human readable name of the catalog
    getter name : String

    @[JSON::Field(ignore: true)]
    getter skip : ExtraSkip?

    @[JSON::Field(ignore: true)]
    getter genre : ExtraGenre?

    @[JSON::Field(ignore: true)]
    getter search : ExtraSearch?

    @[JSON::FakeField]
    def extra(json : ::JSON::Builder) : Nil
      json.array do
        add_extras(json)
      end
    end

    # Returns nothing
    #
    # Allows the addition of entries in the "extra:[]"
    #
    protected def add_extras(json : ::JSON::Builder) : Nil
      skip.as(ExtraSkip).to_json(json) if skip.is_a?(ExtraSkip)
      genre.as(ExtraGenre).to_json(json) if genre.is_a?(ExtraGenre)
      search.as(ExtraSearch).to_json(json) if search.is_a?(ExtraSearch)
    end

    def initialize(@type, @id, @name, @skip = nil, @genre = nil, @search = nil)
    end
  end
end
