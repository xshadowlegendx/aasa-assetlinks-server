
defmodule AasaAssetlinksServer.Router do
  @moduledoc false

  use Plug.Router

  plug :match

  plug Plug.Parsers,
    length: 16_000,
    parsers: [:json],
    json_decoder: {:json, :decode, []}

  forward "/aasa", to: AasaAssetlinksServer.Aasa
  forward "/assetlinks", to: AasaAssetlinksServer.Assetlinks

  forward "/.well-known", to: AasaAssetlinksServer.WellknownAssets

  plug :dispatch

  match _ do
    send_resp(conn, 404, "")
  end
end

