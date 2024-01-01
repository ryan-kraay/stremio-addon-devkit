#
# We will extend the HTTP::Server::Context (like Kemal does) to include
# "params", if it doesn't already exist
#
# The alternative is to try to pass the routes as an extra parameter,
# but prelimiary experiments created conflicts with Kemal
#

class HTTP::Server
  class Context
    {% unless @type.has_method?(:params) %}
      def params
        @params ||= Hash(String, String).new()
      end
    {% end %}
  end
end
