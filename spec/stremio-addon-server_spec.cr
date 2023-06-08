require "./spec_helper"

Spectator.describe Stremio::Addon::Server do
  let(addon) { Stremio::Addon::SQLite3.new DB.open("sqlite3:?journal_mode=wal&synchronous=normal") }

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
      addon.conn.exec "insert into #{addon.table} values (?, ?)", "John Doe", 30
    end.to_not raise_error()

    # Check if we're recycling connections
    expect(addon.conn.scalar "select max(age) from #{addon.table}").to eq(30)
  end
end
