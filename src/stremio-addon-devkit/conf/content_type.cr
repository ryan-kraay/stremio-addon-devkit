
module Stremio::Addon::DevKit::Conf
  # These are the possible content types supported by Stremio
  #  See: https://github.com/Stremio/stremio-addon-sdk/blob/master/docs/api/responses/content.types.md
  enum ContentType
    # `movie`: movie has metadata like name, genre, description, director, actors, images, etc.
    Movie
    # `series`: has all the metadata a movie has, plus an array of episodes
    Series
    # `channel`: created to cover YouTube channels; has name, description and an array of uploaded videos
    Channel
    # `tv`: has name, description, genre; streams for tv should be live (without duration)
    TV

		# source: https://github.com/crystal-lang/crystal/issues/1329#issuecomment-192890286
    def to_s
			{% for member in @type.constants %}
      	return {{member.stringify.downcase}} if self == {{member}}
    	{% end %}
    	value.to_s
  	end
  end
end
