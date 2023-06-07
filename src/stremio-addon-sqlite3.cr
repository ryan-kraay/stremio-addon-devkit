
require "./stremio-addon-server"

module Stremio::Addon

  # A SQLite3 instantiation of a `Stremio::Addon::Server`
  class SQLite3(T) < Server(T)

    # Creates the necessary database tables
    def create_table
      @db.exec "create table #{@table} (name text, age integer)"
    end
  end
end
