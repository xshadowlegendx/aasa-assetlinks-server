defmodule AasaAssetlinksServer.WellknownAssets do
  @moduledoc false

  use Plug.Router

  plug(:match)
  plug(:dispatch)

  get "/apple-app-site-association" do
    data = %{
      appclips: %{apps: []},
      applinks: %{details: []},
      webcredentials: %{apps: []}
    }

    conn
    |> put_resp_content_type("application/json", nil)
    |> put_resp_header("cache-control", "max-age=14400,public")
    |> send_resp(200, :json.encode(data))
  end

  get "/assetlinks.json" do
    data = []

    conn
    |> put_resp_content_type("application/json", nil)
    |> put_resp_header("cache-control", "max-age=14400,public")
    |> send_resp(200, :json.encode(data))
  end
end
