require "../conf/manifest"

module Stremio::Addon::DevKit::Api

  class CatalogResponse

    alias Conf = Stremio::Addon::DevKit::Conf

    getter manifest : Conf::Manifest
    getter catalog : Conf::Catalog

    def initialize(@manifest : Conf::Manifest, @catalog : Conf::Catalog)
    end

    def parse(env)
      # TODO:  Extract what we need from env and include the route
      return self
    end

  end

end
