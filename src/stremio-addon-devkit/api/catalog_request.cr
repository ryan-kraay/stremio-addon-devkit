require "../conf/manifest"

module Stremio::Addon::DevKit::Api

  class CatalogRequest

    alias Conf = Stremio::Addon::DevKit::Conf

    getter manifest : Conf::Manifest
    getter catalog : Conf::Catalog

    def initialize(@manifest : Conf::Manifest, @catalog : Conf::Catalog)
    end

    def parse(env)
      # TODO:  Extract what we need from env and include the route
      return self
    end

    def set_response_headers(env)
      env.response.content_type = "application/json; charset=utf-8"
      # Stremio requires that CORS be set
      env.response.headers["Access-Control-Allow-Origin"] = "*"
      env
    end

  end

end
