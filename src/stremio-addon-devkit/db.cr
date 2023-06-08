module Stremio::Addon::DevKit
  # An abstracted `DB` interface for Stremio Addons
  class DB(T)
    # Constructs a DB instance using *db* as a `DB.open` connection.
    # *table* refers to the database table that will be used
    def initialize(@db : T, @table = "meta")
    end

    # Returns the table name
    def table
      @table
    end

    # Returns the underlying database connection
    def conn
      @db
    end

    # This is a convince function for unit testing
    #
    # WARNING:  This WILL delete ALL the database content
    def delete_all_data
      @db.exec "delete from #{@table}"
    end
  end
end
