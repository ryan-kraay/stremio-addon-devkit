module Stremio::Addon::DevKit::Conf
  # This should be customized based on *your* addon
  #  See: https://github.com/Stremio/stremio-addon-sdk/blob/master/docs/api/responses/manifest.md#filtering-properties
  #
  # WARNING:  This **IS** case sensative and _should_ be lower-case
  # NOTE:  These values **must** correspond to the names used in the url (ie: /<userdata>/meta/<content-type>/..., /catalog/<content-type>/...)
  enum ResourceType
    Catalog
    #    Meta # confirmed
    #    Stream # confirmed
    #    Subtitles
    #    Addon_catalog

		# source: https://github.com/crystal-lang/crystal/issues/1329#issuecomment-192890286
    def to_s
			{% for member in @type.constants %}
      	return {{member.stringify.downcase}} if self == {{member}}
    	{% end %}
    	value.to_s
  	end
  end
end

