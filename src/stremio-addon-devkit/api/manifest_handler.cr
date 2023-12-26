require "./route_handler"
require "./catalog_request"
#require "../userdata/session"

module Stremio::Addon::DevKit::Api

  class ManifestHandler < RouteHandler

    alias CatalogHandler = HTTP::Server::Context, CatalogRequest -> Nil

    # alias CatalogHandler = CatalogRequest(ManifestT, CatalogT), HTTP::Server::Context -> _
    #def route_catalogs(manifest, &handler : CatalogHandler)
    def route_catalogs(manifest, &handler : HTTP::Server::Context, CatalogRequest -> _)
      manifest.catalogs.each do |catalog|
        self.get "/catalog/#{catalog.type}/#{catalog.id}.json" do |env|
          addon = CatalogRequest.new(manifest, catalog).parse(env)
          handler.call(env, addon)
        end
      end
    end

    def bind(manifest, catalog_handler : Nil | (HTTP::Server::Context, CatalogRequest -> _) = None )
      # TODO: assert length of manifest.catalogs if no handler is provided
      route_catalogs(manifest, &catalog_handler)
    end

  end

end
