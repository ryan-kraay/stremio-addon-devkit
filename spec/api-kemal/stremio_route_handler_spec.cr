require "../../src/stremio-addon-devkit/stremio_route_handler"
require "./spec_helper"

Kemal.run

Spectator.describe Stremio::Addon::DevKit::Api::StremioRouteHandler do
  alias StremioRouteHandler = Stremio::Addon::DevKit::Api::StremioRouteHandler

  let(router) { StremioRouteHandler.new }
  before_each do
    reset_kemal do
      # All our added handlers need to be added _before_ the setup()
      # and _after_ the clear()
      add_handler router
    end
  end

  it "implicity adds redirects" do
    original_url = "/local/foo-bar"
    encoded_url = "/local/foo%2Dbar"
    router.add_route "GET", original_url do |env|
      env.response.print "Foobar"
    end

    get original_url
    expect(response.body).to eq "Foobar"

    expect do
      get encoded_url
    end.to_not raise_error
    expect(response.status_code).to eq(301)
    expect(response.headers["location"]).to eq(original_url)
  end

  it "uses kemal http methods to add routes" do
    router.get "/get-url" do |env|
      env.response.print "GOTTEN"
    end
    # also supports:
    #   router.get|post|put|patch|delete|options

    get "/get-url"
    expect(response.body).to eq "GOTTEN"

    expect do
      get "/get%2Durl"
    end.to_not raise_error
    expect(response.status_code).to eq(301)
    expect(response.headers["location"]).to eq("/get-url")
  end

  it "supports wildcard urls" do
    extra = nil
    # The observed behavior of wildcards is that
    # **everything** after the wildcard is ignored
    router.get "/:userdata/get-url/f*/:extra/whatever" do |env|
      extra = env.params.url.fetch("extra", "unset")
      env.response.print "accepted"
    end

    get "/test/get-url/foo/bar"

    expect(response.body).to eq "accepted"
    expect(extra).to eq "unset"

    expect do
      get "/test/get%2Durl/foo/bar"
    end.to_not raise_error

    expect(response.status_code).to eq(301)
    expect(response.headers["location"]).to eq("/test/get-url/foo/bar")
  end

  it "supports url parameters" do
    userdata = nil
    cgi = nil
    router.get "/:userdata/get-url" do |env|
      userdata = env.params.url.fetch("userdata", "unset")
      cgi = env.params.query.fetch("cgi", "unset")
      env.response.print "done"
    end

    get "/test/get-url?cgi=received"

    expect(response.body).to eq "done"
    expect(cgi).to eq "received"
    expect(userdata).to eq "test"

    expect do
      get "/test/get%2Durl?cgi=received"
    end.to_not raise_error

    expect(response.status_code).to eq(301)
    expect(response.headers["location"]).to eq("/test/get-url?cgi=received")
  end

  describe "#encode" do
    it "will properly encode" do
      subject = "foo-bar"
      expected = "foo%2Dbar"

      expect(StremioRouteHandler.encode(subject)).to eq(expected)
    end
  end
end
