defmodule AasaAssetlinksServer.WellknownAssets do
  @moduledoc false

  use Plug.Router

  alias AasaAssetlinksServer.InmemStore

  plug(:match)
  plug(:dispatch)

  defp put_applink(data, {"aasa:" <> app_id, %{"applink" => %{"components" => components}}}) do
    %{
      data |
      applinks: %{
        details: [%{appID: app_id, components: components} | data.applinks.details]
      }
    }
  end

  defp put_applink(data, _), do: data

  defp put_webcredential(data, {"aasa:" <> app_id, %{"webcredential" => %{}}}) do
    %{
      data |
      webcredentials: %{
        apps: [app_id | data.webcredentials.apps]
      }
    }
  end

  defp put_webcredential(data, _), do: data

  get "/apple-app-site-association" do
    %{"aasa" => aasa} = InmemStore.get_aasa_assetlinks()

    data = %{
      appclips: %{apps: []},
      applinks: %{details: []},
      webcredentials: %{apps: []}
    }

    data =
      Enum.reduce(aasa, data, fn aasa, data ->
        data
        |> put_applink(aasa)
        |> put_webcredential(aasa)
      end)

    conn
    |> put_resp_content_type("application/json", nil)
    |> put_resp_header("cache-control", "max-age=14400,public")
    |> send_resp(200, :json.encode(data))
  end

  get "/assetlinks.json" do
    %{"assetlinks" => assetlinks} = InmemStore.get_aasa_assetlinks()

    data = Enum.map(assetlinks, fn {"assetlinks:" <> app_id, app} ->
      data = %{
        relation: app["relation"],
        target: %{
          namespace: app["namespace"],
          sha256_cert_fingerprints: app["sha256_cert_fingerprints"]
        }
      }

      %{
        data |
        target:
          data.target
          |> Map.put(
            (if data.target.namespace == "web", do: :site, else: :package_name),
            app_id
          )
          |> Map.update(
            :sha256_cert_fingerprints,
            [],
            fn
              nil -> []

              any -> any
            end
          )
      }
    end)

    conn
    |> put_resp_content_type("application/json", nil)
    |> put_resp_header("cache-control", "max-age=14400,public")
    |> send_resp(200, :json.encode(data))
  end
end
