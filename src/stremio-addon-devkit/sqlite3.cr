require "./db"
require "sqlite3/exception"

module Stremio::Addon::DevKit
  # A SQLite3 instantiation of a `Stremio::Addon::DevKit::DB`
  class SQLite3(T) < DB(T)
    # Creates the necessary database tables
    def create_table
      create_movies
    end

    # Constructs a movies table
    protected def create_movies
      # Crystal SQLite3 is rather limited on supported types
      #  https://github.com/crystal-lang/crystal-sqlite3/blob/master/src/sqlite3/type.cr
      @db.exec <<-EOL
        CREATE TABLE #{@t_movies} (
          uid       TEXT PRIMARY KEY UNIQUE NOT NULL,
          priority  INTEGER NOT NULL
        ) WITHOUT ROWID
      EOL
      @db.exec <<-EOL
        CREATE INDEX priority_indexed ON #{@t_movies}(priority)
      EOL
    end

    protected def insert_unless_duplicate(*args) : Bool
      is_added = true
      begin
        @db.exec *args
      rescue ex : ::SQLite3::Exception
        if ex.message.as?(String) && ex.message.as(String).starts_with?("UNIQUE constraint failed:")
          is_added = false
        else
          raise ex
        end
      end

      is_added
    end
  end
end
