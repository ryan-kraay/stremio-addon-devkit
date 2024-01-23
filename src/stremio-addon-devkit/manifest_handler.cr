require "./stremio_route_handler"
require "./catalog_movie_request"
require "./catalog_movie_response"

require "./manifest_request"
require "./manifest_response"

require "./multi_block_handler"

# require "../userdata/session"

module Stremio::Addon::DevKit::Api
  class ManifestBindingError < Exception; end

  class ManifestHandler < StremioRouteHandler
    alias Conf = Stremio::Addon::DevKit

    # Assigns all manifest.catalogs objects with `&handler`.
    # If `&handler` returns a CatalogMovieResponse, this response will be serialized
    # in such a way that Stremio Clients can understand it (ie: proper headers will be set)
    # If `&handler` returns `nil`, this means that the callback will provide
    # the response
    def route_catalogs(manifest, &handler : HTTP::Server::Context, CatalogMovieRequest -> CatalogMovieResponse?)
      resource = ResourceType::Catalog

      manifest.catalog_movies.each do |catalog|
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

    def route_manifest(manifest, &handler : HTTP::Server::Context, ManifestRequest -> ManifestResponse?)
      self.get "/manifest.json" do |env|
        addon = ManifestRequest.new(manifest).parse(env)
        response = handler.call(env, addon)
        if response.is_a?(ManifestResponse)
          response = response.as(ManifestResponse)
          env.response.print response.to_json
          addon.set_response_headers env
        end

        nil
      end
    end

    def bind(manifest, &block)
      callbacks = MultiBlockHandler.new
      yield callbacks

      if !callbacks.catalog_movie? && !manifest.catalog_movies.empty?
        raise ManifestBindingError.new("Movie CatalogMovies defined, but catalog_movie callback was not provided")
      elsif !manifest.catalog_movies.empty?
        route_catalogs(manifest, &callbacks.catalog_movie)
      end

      # we will always create a manifest
      if !callbacks.manifest?
        callbacks.manifest do |env, addon|
          addon.manifest
        end
      end
      route_manifest(manifest, &callbacks.manifest)
    end
  end
end
