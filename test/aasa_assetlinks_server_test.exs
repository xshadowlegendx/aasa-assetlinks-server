defmodule AasaAssetlinksServerTest do
  use ExUnit.Case, async: true
  use Plug.Test

  setup do
    []
  end

  describe ".well-known assets" do
    test "assetlinks.json returns correct format", _context do
      conn =
        :get
        |> conn("/.well-known/assetlinks.json")
        |> AasaAssetlinksServer.Router.call([])

      assert conn.status == 200
      assert get_resp_header(conn, "content-type") == ["application/json"]
    end

    test "aasa returns correct format", _context do
      conn =
        :get
        |> conn("/.well-known/apple-app-site-association")
        |> AasaAssetlinksServer.Router.call([])

      assert conn.status == 200
      assert get_resp_header(conn, "content-type") == ["application/json"]
    end
  end
end
