require "./catalog_movie_request"

module Stremio::Addon::DevKit::Api

  # Crystal, by design, does not support passing multiple blocks
  # so, we fake it by creating a method, which will capture a block
  class MultiBlockHandler

    macro define_handler(name, request_type)
      @{{name.id}} : (HTTP::Server::Context, {{request_type}} -> Nil) | Nil = nil

      # our setter
      # By allowing the use of a block, it gives the user more flexibility
      #  regarding the parameters _they_ decide to use and the return value
      def {{name.id}}(&handler : HTTP::Server::Context, {{request_type}} -> _)
        @{{name.id}} = ->(env : HTTP::Server::Context, addon : {{request_type}}) do
          handler.call(env, addon)
          # Regardless of the return type of our handler, we always
          # need to return nil, otherwise we get typecast errors
          nil
        end
        # we return self, so we can easily chain these methods together
        return self
      end

      # our getter
      # Throws a TypeCastError if it was not set
      def {{name.id}}
        @{{name.id}}.as(Proc(HTTP::Server::Context, {{request_type}}, Nil))
      end

      # Our check to see if the handler is set
      def {{name.id}}?
        return !@{{name.id}}.is_a?(Nil)
      end
    end

    define_handler(:catalog, CatalogMovieRequest)
  end

end
