defmodule AasaAssetlinksServerTest do
  use ExUnit.Case, async: true
  use Plug.Test

  setup do
    []
  end

  describe "aasa" do
    @aasa_app_valid_config %{
      "app_id" => "ABCD012BBX.org.acme.app",
      "webcredential" => %{},
      "applink" => %{
        "components" => [%{
          "#" => "*",
          "?" => "*",
          "/" => "*"
        }]
      }
    }

    test "able to add new app with correct format", _context do
      conn =
        :put
        |> conn("/aasa", @aasa_app_valid_config)
        |> AasaAssetlinksServer.Router.call([])

      app = AasaAssetlinksServer.InmemStore.get_app(:aasa, @aasa_app_valid_config["app_id"])

      assert conn.status == 204
      assert not is_nil(app)
      assert app |> elem(1) |> Map.get("webcredential") == %{}
      assert app |> elem(1) |> Map.get("applink") == @aasa_app_valid_config["applink"]
    end

    test "able to remove app", _context do
      conn =
        :put
        |> conn("/aasa", @aasa_app_valid_config)
        |> AasaAssetlinksServer.Router.call([])

      app = AasaAssetlinksServer.InmemStore.get_app(:aasa, @aasa_app_valid_config["app_id"])

      assert conn.status == 204
      assert not is_nil(app)

      conn =
        :delete
        |> conn("/aasa", @aasa_app_valid_config)
        |> AasaAssetlinksServer.Router.call([])

      app = AasaAssetlinksServer.InmemStore.get_app(:aasa, @aasa_app_valid_config["app_id"])

      assert conn.status == 204
      assert is_nil(app)
    end

    test "able to unset applink components", _context do
      :put
      |> conn("/aasa", @aasa_app_valid_config)
      |> AasaAssetlinksServer.Router.call([])

      initial_app = AasaAssetlinksServer.InmemStore.get_app(:aasa, @aasa_app_valid_config["app_id"])

      conn =
        :put
        |> conn("/aasa", %{@aasa_app_valid_config | "applink" => %{}})
        |> AasaAssetlinksServer.Router.call([])

      after_app = AasaAssetlinksServer.InmemStore.get_app(:aasa, @aasa_app_valid_config["app_id"])

      assert conn.status == 204
      assert after_app |> elem(1) |> Map.get("applink") == %{}
      assert initial_app |> elem(1) |> Map.get("applink") != after_app |> elem(1) |> Map.get("applink")
    end

    test "invalid app_id format", _context do
      conn =
        :put
        |> conn("/aasa", %{@aasa_app_valid_config | "app_id" => "ABC.org.acme.app"})
        |> AasaAssetlinksServer.Router.call([])

      assert conn.status == 400
    end

    test "invalid applink format", _context do
      conn =
        :put
        |> conn("/aasa", %{@aasa_app_valid_config | "applink" => %{"components" => %{}}})
        |> AasaAssetlinksServer.Router.call([])

      assert conn.status == 400

      conn =
        :put
        |> conn("/aasa", %{@aasa_app_valid_config | "applink" => []})
        |> AasaAssetlinksServer.Router.call([])

      assert conn.status == 400
    end
  end

  describe "assetlinks" do
    @assetlinks_app_valid_config %{
      "app_id" => "com.example.app",
      "relation" => [
        "delegate_permission/common.get_login_creds",
        "delegate_permission/common.handle_all_urls"
      ],
      "sha256_cert_fingerprints" => [
        "25:0D:9B:52:B1:78:23:BC:49:43:E0:A4:B0:FB:1D:C0:40:1D:79:F4:A6:C8:97:E8:FE:F0:70:00:F4:59:7F:0E"
      ]
    }

    test "able to add new app with correct format", _context do
      conn =
        :put
        |> conn("/assetlinks", @assetlinks_app_valid_config)
        |> AasaAssetlinksServer.Router.call([])

      app = AasaAssetlinksServer.InmemStore.get_app(:assetlinks, @assetlinks_app_valid_config["app_id"])

      assert conn.status == 204
      assert not is_nil(app)
      assert app |> elem(1) |> Map.get("namespace") == "android_app"
      assert app |> elem(1) |> Map.get("relation") == @assetlinks_app_valid_config["relation"]
      assert app |> elem(1) |> Map.get("sha256_cert_fingerprints") == @assetlinks_app_valid_config["sha256_cert_fingerprints"]
    end

    test "able to remove app", _context do
      conn =
        :put
        |> conn("/assetlinks", @assetlinks_app_valid_config)
        |> AasaAssetlinksServer.Router.call([])

      app = AasaAssetlinksServer.InmemStore.get_app(:assetlinks, @assetlinks_app_valid_config["app_id"])

      assert conn.status == 204
      assert not is_nil(app)

      conn =
        :delete
        |> conn("/assetlinks", @assetlinks_app_valid_config)
        |> AasaAssetlinksServer.Router.call([])

      app = AasaAssetlinksServer.InmemStore.get_app(:assetlinks, @assetlinks_app_valid_config["app_id"])

      assert conn.status == 204
      assert is_nil(app)
    end

    test "test invalid sha256 cert fingerprints", _context do
      conn =
        :put
        |> conn("/assetlinks", %{@assetlinks_app_valid_config | "sha256_cert_fingerprints" => ["abc:df"]})
        |> AasaAssetlinksServer.Router.call([])

      assert conn.status == 400
    end

    test "test invalid relation", _context do
      conn =
        :put
        |> conn("/assetlinks", %{@assetlinks_app_valid_config | "relation" => ["abc:df"]})
        |> AasaAssetlinksServer.Router.call([])

      assert conn.status == 400
    end
  end

  describe ".well-known assets" do
    test "assetlinks.json returns correct format", _context do
      :ok = AasaAssetlinksServer.InmemStore.set_assetlinks_app(
        @assetlinks_app_valid_config["app_id"],
        @assetlinks_app_valid_config
      )

      conn =
        :get
        |> conn("/.well-known/assetlinks.json")
        |> AasaAssetlinksServer.Router.call([])

      resp = :json.decode(conn.resp_body)

      assert conn.status == 200
      assert get_resp_header(conn, "content-type") == ["application/json"]
      assert is_list(resp)
    end

    test "aasa returns correct format", _context do
      :ok = AasaAssetlinksServer.InmemStore.set_aasa_app(
        @aasa_app_valid_config["app_id"],
        @aasa_app_valid_config
      )

      conn =
        :get
        |> conn("/.well-known/apple-app-site-association")
        |> AasaAssetlinksServer.Router.call([])

      resp = :json.decode(conn.resp_body)

      assert conn.status == 200
      assert get_resp_header(conn, "content-type") == ["application/json"]
      assert is_map(resp)
    end
  end
end
