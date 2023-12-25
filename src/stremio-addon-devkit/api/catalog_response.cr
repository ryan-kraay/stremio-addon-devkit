module Stremio::Addon::DevKit::Api

  class CatalogResponse(ManifestT, CatalogT)

    getter manifest : ManifestT
    getter catalog : CatalogT

    def initialize(@manifest : ManifestT, @catalog : CatalogT, env)
      # TODO:  Extract what we need from env and include the route
    end

  end

end
