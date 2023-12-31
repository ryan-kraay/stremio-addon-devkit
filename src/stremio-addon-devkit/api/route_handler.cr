#
# As this file contains modified version of:
#  https://github.com/kemalcr/kemal/blob/13fd4f8b2f5d3003d0ad0c43e0b3a0f324abefb0/src/kemal/route_handler.cr
#  https://github.com/kemalcr/kemal/blob/13fd4f8b2f5d3003d0ad0c43e0b3a0f324abefb0/src/kemal/route.cr
#
# Only the contents of THIS FILE will be released under the same MIT license as Kemal:
#  https://github.com/kemalcr/kemal/blob/13fd4f8b2f5d3003d0ad0c43e0b3a0f324abefb0/LICENSE
#

require "http/server/handler"
require "http/server/context"
require "radix"
require "uri"
require "../ext"

module Stremio::Addon::DevKit::Api

  struct Route
    getter method, path, handler
    @handler : HTTP::Server::Context -> String

    def initialize(@method : String, @path : String, &handler : HTTP::Server::Context -> _)
      @handler = ->(context : HTTP::Server::Context) do
        output = handler.call(context)
        output.is_a?(String) ? output : ""
      end
    end
  end

  # Inspired by Kemal::RouteHandler, this Handler is not
  # a singleton nor will it return a http-404 if a match is not made
  # 
  # It provides a Kemal::RouteHandler-like interface, but respects Kemals
  # request that libraries use `add_handler` to inject routes, rather
  # than adding them to the global Kemal::RouteHandler.
  class RouteHandler
    include HTTP::Handler

    @cached_routes : Hash(String, Radix::Result(Route))
    CACHED_ROUTES_LIMIT = 64
    HTTP_METHODS   = %w(get post put patch delete options)

    def initialize()
      @routes = Radix::Tree(Route).new
      @cached_routes = Hash(String, Radix::Result(Route)).new
    end


    #
    # A handful of utility functions
    #
    def self.redirect(env : HTTP::Server::Context, url : String, status_code : Int32 = 302, *, body : String? = nil, close : Bool = true)
      response = env.response

      response.headers.add "Location", url.to_s
      response.status_code = status_code
      response.print(body) if body
      response.close if close
    end

    #
    # Some older stremio clients (ie: Android TV) incorrectly encode
    # path, so they're incompatible with https://datatracker.ietf.org/doc/html/rfc3986#section-2.3
    # Specifically, "_,.,- and ~" are encoded by these clients.
    # This function will encode strings in a way that's compatible with these
    # non-conformant clients
    #
    # ie: "foo-bar" === "foo%2Dbar"
    def self.encode_stremio(path : String) : String
      String.build do |io|
        URI.encode(path, io, space_to_plus: false) do |byte|
          # a butchered URI.unreserved?
          char = byte.unsafe_chr
          char.ascii_alphanumeric? || char.in?('/', ':')
        end
      end
    end

    # Adds a given route to routing tree.
    # Should not be needed to call directly, use the macros below
    def add_route(method : String, path : String, &handler : HTTP::Server::Context -> _)
      add_to_radix_tree method, path, Route.new(method, path, &handler)
    end

    # A macro to create the familar `get "/path" &block` syntax
    # ie:
    # router = RouteHandler.new()
    # add_handler router
    #
    # router.get "/:user/my-url" do |env|
    #   env.response.print "hello #{env.params.url["user"]}"
    # end
    {% for method in HTTP_METHODS %}
      def {{method.id}}(path : String, &block : HTTP::Server::Context -> _)
  # TODO-rkr      raise Kemal::Exceptions::InvalidPathStartException.new({{method}}, path) unless Kemal::Utils.path_starts_with_slash?(path)
        add_route({{method}}.upcase, path, &block)
      end
    {% end %}

    def call(context : HTTP::Server::Context)
      route = lookup_route(context.request.method, context.request.path)
      return call_next(context) unless route.found?

      # Our context is missing the parameters provided by our route
      route.params.each { |key, value| context.params.url[key] = unescape_url_param(value) }
      route.payload.handler.call(context)
    end

    # Looks up the route from the Radix::Tree for the first time and caches to improve performance.
    def lookup_route(verb : String, path : String)
      lookup_path = radix_path(verb, path)

      if cached_route = @cached_routes[lookup_path]?
        return cached_route
      end

      route = @routes.find(lookup_path)

      if verb == "HEAD" && !route.found?
        # On HEAD requests, implicitly fallback to running the GET handler.
        route = @routes.find(radix_path("GET", path))
      end

      if route.found?
        @cached_routes.clear if @cached_routes.size == CACHED_ROUTES_LIMIT
        @cached_routes[lookup_path] = route
      end

      route
    end

    private def radix_path(method, path)
      '/' + method + path
    end

    private def add_to_radix_tree(method, path, route)
      node = radix_path method, path
      @routes.add node, route
    end

    # source: https://github.com/kemalcr/kemal/blob/master/src/kemal/param_parser.cr
    private def unescape_url_param(value : String)
      value.empty? ? value : URI.decode(value)
    rescue
      value
    end

  end

end
