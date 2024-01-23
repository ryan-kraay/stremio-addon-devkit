require "./manifest"

module Stremio::Addon::DevKit::Api
  abstract class StremioBaseRequest
    alias Conf = Stremio::Addon::DevKit::Conf

    getter manifest : Conf::Manifest

    def initialize(@manifest : Conf::Manifest)
    end

    # Extract meaningful content from env.request
    abstract def parse(env)

    #      # TODO:  Extract what we need from env and include the route
    #      return self
    #    end

    # properly write the response headers in such a way that the stremio
    # client understands.
    def set_response_headers(env)
      env.response.content_type = "application/json; charset=utf-8"
      # Stremio requires that CORS be set
      env.response.headers["Access-Control-Allow-Origin"] = "*"
      env
    end
  end
end
