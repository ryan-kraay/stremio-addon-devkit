require "./stremio_base_request"

module Stremio::Addon::DevKit::Api

  class CatalogMovieRequest < StremioBaseRequest

    getter catalog : Conf::Catalog

    def initialize(@manifest : Conf::Manifest, @catalog : Conf::Catalog)
    end

    def parse(env)
      # TODO:  Extract what we need from env and include the route
      return self
    end

  end

end
