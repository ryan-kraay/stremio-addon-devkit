require "./db"

module Stremio::Addon::DevKit
  # A SQLite3 instantiation of a `Stremio::Addon::DevKit::DB`
  class SQLite3(T) < DB(T)
    # Creates the necessary database tables
    def create_table
      @db.exec "create table #{@table} (name text, age integer)"
    end
  end
end
