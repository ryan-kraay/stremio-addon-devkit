require "./catalog_movie_request"
require "./manifest_response"
require "../conf/manifest"

module Stremio::Addon::DevKit::Api

  alias ManifestRequest = Stremio::Addon::DevKit::Conf::Manifest

  # Crystal, by design, does not support passing multiple blocks
  # so, we fake it by creating a method, which will capture a block
  class MultiBlockHandler

    macro define_handler(name, request_type, response_type)
      @{{name.id}} : (HTTP::Server::Context, {{request_type}} -> {{response_type}}) | Nil = nil

      # our setter
      # By allowing the use of a block, it gives the user more flexibility
      #  regarding the parameters _they_ decide to use and the return value
      def {{name.id}}(&handler : HTTP::Server::Context, {{request_type}} -> {{response_type}})
        @{{name.id}} = ->(env : HTTP::Server::Context, addon : {{request_type}}) do
          # TODO: It's complicated to create &handler with an optional response_type, so we have for cast the result after it's called
          handler.call(env, addon).as({{response_type}})
        end
        # we return self, so we can easily chain these methods together
        return self
      end

      # our getter
      # Throws a TypeCastError if it was not set
      def {{name.id}}
        @{{name.id}}.as(Proc(HTTP::Server::Context, {{request_type}}, {{response_type}}))
      end

      # Our check to see if the handler is set
      def {{name.id}}?
        return !@{{name.id}}.is_a?(Nil)
      end
    end

    define_handler(:catalog_movie, CatalogMovieRequest, CatalogMovieResponse?)
    define_handler(:manifest, ManifestRequest, ManifestResponse?)
  end

end
