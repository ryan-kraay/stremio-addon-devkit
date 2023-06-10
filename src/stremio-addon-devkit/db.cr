module Stremio::Addon::DevKit
  # An abstracted `DB` interface for Stremio Addons
  abstract class DB(T)
    # The table which contains the metadata for movies
    getter t_movies : String

    # Constructs a DB instance using *db* as a `DB.open` connection.
    # *table_prefix* will prefix all tables with this value
    def initialize(@db : T, table_prefix = "meta_")
      @t_movies = "#{table_prefix}movies"
    end

    # Returns the underlying database connection
    def conn
      @db
    end

    # This is a convince function for unit testing
    #
    # WARNING:  This WILL delete ALL the database content
    def delete_all_data
      [t_movies].each do |table|
        @db.exec "delete from #{table}"
      end
    end

    # Returns true if the content was added, false if the content already exists, raises SQLite3::Statement on error
    #
    # Adds a new entry to this database.
    # Parameters:
    #  * `uid`: A unique TEXT identifier.  Ideally suitable for "tt<imdb-id>"'s.
    #  * `priority`: A user defined ranking.  Useful for ranking "the most popular shows"
    def import_movie(uid : String, priority : Int32) : Bool
      insert_unless_duplicate "INSERT INTO #{@t_movies} (uid, priority) VALUES (?, ?)", uid, priority
    end

    # Returns true if the content was added, false if the content already exists, raises an Exception upon error
    protected abstract def insert_unless_duplicate(*args) : Bool
  end
end
