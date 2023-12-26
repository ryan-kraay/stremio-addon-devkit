require "../../src/stremio-addon-devkit/api/route_handler"
require "./spec_helper"

get "/" do
  "Hello World!"
end

Kemal.run
  

Spectator.describe Stremio::Addon::DevKit::Api::RouteHandler do
  alias RouteHandler = Stremio::Addon::DevKit::Api::RouteHandler

  let(router) { RouteHandler.new }
  before_each do
    reset_kemal do
      # All our added handlers need to be added _before_ the setup()
      # and _after_ the clear()
      add_handler router
    end
  end

  it "renders globally defined routes" do
    get "/"
    expect(response.body).to eq "Hello World!"
  end

  it "renders locally defined routes" do
    #Kemal::RouteHandler::INSTANCE.add_route "GET", "/local" do
    router.add_route "GET", "/local" do |env|
      env.response.print "Foobar"
    end

    # make sure our existing (global) route works
    get "/"
    expect(response.body).to eq "Hello World!"

    get "/local"
    expect(response.body).to eq "Foobar"
  end

  it "uses kemal http methods to add routes" do
    router.get "/get-url" do |env|
      env.response.print "GOTTEN"
    end
    # also supports:
    #   router.get|post|put|patch|delete|options

    get "/get-url"
    expect(response.body).to eq "GOTTEN"
  end

  it "resets locally defined routes" do
    expect do
      get "/local"
    end.to raise_error(Kemal::Exceptions::RouteNotFound)
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
  end
end
