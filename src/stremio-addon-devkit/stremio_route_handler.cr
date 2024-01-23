require "./route_handler"

module Stremio::Addon::DevKit
  #
  # Some older stremio clients (ie: Android TV) incorrectly encode
  # paths, so they're incompatible with https://datatracker.ietf.org/doc/html/rfc3986#section-2.3
  # Specifically, "_,.,- and ~" are encoded by these clients (rfc3986 says they should NOT).
  # This class will encode strings in a way that's compatible with these
  # non-conforming clients
  #
  class StremioRouteHandler < RouteHandler
    # Encodes a string such that older stremio clients can access the urls
    # ie: "foo-bar" === "foo%2Dbar"
    def self.encode(path : String) : String
      String.build do |io|
        URI.encode(path, io, space_to_plus: false) do |byte|
          # a butchered version URI.unreserved?
          char = byte.unsafe_chr
          char.ascii_alphanumeric? || char.in?('/', ':', '.', '*')
        end
      end
    end

    # Anytime routes are added, we'll also add an optional redirect
    # if any parameters need to be escaped for non-compliant stremio clients
    def add_route(method : String, path : String, &handler : HTTP::Server::Context -> _)
      super(method, path, &handler)

      begin
        encoded_path = self.class.encode(path)
        super(method, encoded_path) do |env|
          # env.path will contain placeholders (ie: /:foo/) that need
          # to be propigated in our redirect.  However, we need to identify
          # what parameters actually changed in our encoded_path.
          #
          # Our solution is to split our unencoded_path, our encoded_path (to
          # determine "what is different")
          unencoded = path.split('/')
          encoded = encoded_path.split('/')
          current = env.request.path.split('/')
          result = Array(String).new

          pos = 0
          unencoded.each do
            if unencoded[pos] == encoded[pos]
              # Either the path is identical or this is a placeholder
              if encoded[pos].includes?('*')
                # If a wildcard appears in our path **everything** matches
                #  so, we'll just copy whatever is leftover from current
                #  and break
                result += current[pos..(current.size - 1)]
                break
              else
                result << current[pos]
              end
            else
              # This content was encoded, so we want the unencoded variant
              result << unencoded[pos]
            end
            pos += 1
          end

          final_path = result.join("/")
          if env.request.query.is_a?(String)
            final_path += "?" + env.request.query.as(String)
          end

          self.class.redirect env, final_path, status_code: 301
        end
      rescue Radix::Tree::DuplicateError
        # URI.encode_path(catalog.id) == catalog.id
      end
    end
  end
end
