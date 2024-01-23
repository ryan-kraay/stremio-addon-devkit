require "./catalog_base"

module Stremio::Addon::DevKit::Conf
  @[JSON::Serializable::Options(ignore_deserialize: true)]
  class CatalogMovie < CatalogBase
    def initialize(@id, @name, @skip = nil, @genre = nil, @search = nil)
      @type = ContentType::Movie
    end
  end
end
