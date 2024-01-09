require "./stremio_route_handler"
require "./catalog_movie_request"
require "./catalog_movie_response"
require "./multi_block_handler"

#require "../userdata/session"

module Stremio::Addon::DevKit::Api

  class ManifestBindingError < Exception; end

  class ManifestHandler < StremioRouteHandler
		alias Conf = Stremio::Addon::DevKit::Conf

    # Assigns all manifest.catalogs objects with `&handler`.
    # If `&handler` returns a CatalogMovieResponse, this response will be serialized
    # in such a way that Stremio Clients can understand it (ie: proper headers will be set)
    # If `&handler` returns `nil`, this means that the callback will provide
    # the response
    def route_catalogs(manifest, &handler : HTTP::Server::Context, CatalogMovieRequest -> CatalogMovieResponse?)
			resource = Conf::ResourceType::Catalog

      manifest.catalogs.each do |catalog|
        self.get "/#{resource}/#{catalog.type}/#{catalog.id}.json" do |env|
          addon = CatalogMovieRequest.new(manifest, catalog).parse(env)
          response = handler.call(env, addon)
          if response.is_a?(CatalogMovieResponse)
            # We have received a respones object, we'd like to send to the user
            response = response.as(CatalogMovieResponse)
            env.response.print response.to_json
            addon.set_response_headers env
          end

          nil
        end
      end
    end

    def bind(manifest, &block)
      callbacks = MultiBlockHandler.new
      yield callbacks

      if !callbacks.catalog_movie? && !manifest.catalogs.empty?
        raise ManifestBindingError.new("Manifest catalogs defined, but catalog callback was not provided")
      elsif !manifest.catalogs.empty?
        route_catalogs(manifest, &callbacks.catalog_movie)
      end

    end

  end

end
