require "./stremio_base_request"

module Stremio::Addon::DevKit::Api
  class ManifestRequest < StremioBaseRequest
    def parse(env)
      # TODO:  Extract what we need from env and include the route
      return self
    end
  end
end
