require "./route_handler"
require "./catalog_response"
#require "../userdata/session"

module Stremio::Addon::DevKit::Api

  class ManifestHandler < RouteHandler

    alias CatalogHandler = HTTP::Server::Context, CatalogResponse -> Nil

    # alias CatalogHandler = CatalogResponse(ManifestT, CatalogT), HTTP::Server::Context -> _
    def route_catalogs(manifest, &handler : CatalogHandler)
      manifest.catalogs.each do |catalog|
        get "/catalog/#{catalog.type}/#{catalog.id}.json" do |env|
          addon = CatalogResponse.new(manifest, catalog).parse(env)
          handler.call(env, addon)
        end
      end
    end

    def bind(manifest, &catalog_handler : CatalogHandler)
      # TODO: assert length of manifest.catalogs if no handler is provided
      route_catalogs(manifest, &catalog_handler)
    end

  end

end
