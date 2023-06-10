require "./spec_helper"

Spectator.describe Stremio::Addon::DevKit::DB do
  let(addon) { Stremio::Addon::DevKit::SQLite3.new DB.open("sqlite3:?journal_mode=wal&synchronous=normal") }

  before_each {
    # FYI:  let() and subject() are lazy-loaded, but are not accessible within a before_all {}
    expect do
      addon.create_table
    end.to_not raise_error()
  }

  it "works" do
    expect(false).to eq(false)
  end

  it "connects to a database" do
    expect do
      addon.import_movie(priority: 30, uid: "John Doe")
    end.to_not raise_error()

    # Check if we're recycling connections
    expect(addon.conn.scalar "select max(priority) from #{addon.t_movies}").to eq(30)
  end

  describe "#import_movie" do

    it "inserts data" do
      elements = 10
      (1..elements).each do |x|
        was_added = false
        expect do
          was_added = addon.import_movie(priority: 10, uid: "tt#{x + 1000}")
        end.to_not raise_error()
        expect(was_added).to be_true
      end

      expect(addon.conn.scalar "SELECT count(*) FROM #{addon.t_movies}").to eq(elements)
    end

    it "errors when a duplicate uid is added" do
      uid = "tt1234"
      was_added = false

      expect do
       was_added = addon.import_movie(priority: 30, uid: uid)
      end.to_not raise_error()
      expect(was_added).to be_true

      expect do
        was_added = addon.import_movie(priority: 40, uid: uid)
      end.to_not raise_error()
      expect(was_added).to be_false
    end

  end
end
