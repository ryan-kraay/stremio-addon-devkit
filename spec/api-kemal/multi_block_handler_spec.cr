require "../../src/stremio-addon-devkit/multi_block_handler"
require "./spec_helper"

Spectator.describe Stremio::Addon::DevKit::ManifestHandler do
  alias DevKit = Stremio::Addon::DevKit

  let(manifest) { DevKit::Manifest.build(
    id: "com.stremio.addon.example",
    name: "DemoAddon",
    description: "An example stremio addon",
    version: "0.0.1") do |conf|
    conf << DevKit::CatalogMovie.new(
      id: "movie4u",
      name: "Movies for you")
  end }

  let(movie_request) {
    m = manifest
    DevKit::CatalogMovieRequest.new(m, m.catalog_movies[0])
  }
  let(env) {
    request = HTTP::Request.new("GET", "/")
    response_text = IO::Memory.new(<<-EOL)
HTTP/1.1 200 OK
Date: Mon, 27 Jul 2009 12:28:53 GMT
Server: Apache/2.2.14 (Win32)
Last-Modified: Wed, 22 Jul 2009 19:15:56 GMT
Content-Length: 0
Content-Type: text/html
Connection: Closed
EOL
    response = HTTP::Server::Response.new(response_text)
    HTTP::Server::Context.new(request, response)
  }
  subject { DevKit::MultiBlockHandler.new }

  describe "#initialize" do
    it "will not raise an error" do
      expect do
        subject
      end.to_not raise_error
    end

    it "will fail of callbacks are not defined" do
      expect(subject.catalog_movie?).to eq(false)
      expect do
        subject.catalog_movie.call(env, movie_request)
      end.to raise_error TypeCastError
    end
  end

  describe "#catalog_movie" do
    it "is possible to replace the callback with a block" do
      accessed = false
      s = subject
      s.catalog_movie do
        accessed = true
        nil
      end
      expect(s.catalog_movie?).to eq(true)
      expect do
        s.catalog_movie.call(env, movie_request)
      end.to_not raise_error
      expect(accessed).to eq(true)
    end

    it "is possible to replace the callback with a proc" do
      accessed = false
      proc = ->(env : HTTP::Server::Context, addon : DevKit::CatalogMovieRequest) { accessed = true; nil }

      s = subject
      s.catalog_movie &proc

      expect(s.catalog_movie?).to eq(true)
      expect do
        s.catalog_movie.call(env, movie_request)
      end.to_not raise_error
      expect(accessed).to eq(true)
    end
  end
end
