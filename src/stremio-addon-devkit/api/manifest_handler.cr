require "./stremio_route_handler"
require "./catalog_request"
require "./multi_block_handler"

#require "../userdata/session"

module Stremio::Addon::DevKit::Api

  class ManifestBindingError < Exception; end

  class ManifestHandler < StremioRouteHandler
		alias Conf = Stremio::Addon::DevKit::Conf

    # alias CatalogHandler = CatalogRequest(ManifestT, CatalogT), HTTP::Server::Context -> _
    #def route_catalogs(manifest, &handler : CatalogHandler)
    def route_catalogs(manifest, &handler : HTTP::Server::Context, CatalogRequest -> _)
			resource = Conf::ResourceType::Catalog

      manifest.catalogs.each do |catalog|
        self.get "/#{resource}/#{catalog.type}/#{catalog.id}.json" do |env|
          addon = CatalogRequest.new(manifest, catalog).parse(env)
          handler.call(env, addon)
        end
      end
    end

    def bind(manifest, &block)
      callbacks = MultiBlockHandler.new
      yield callbacks

      if !callbacks.catalog? && !manifest.catalogs.empty?
        raise ManifestBindingError.new("Manifest catalogs defined, but catalog callback was not provided")
      elsif !manifest.catalogs.empty?
        route_catalogs(manifest, &callbacks.catalog)
      end

    end

  end

end
