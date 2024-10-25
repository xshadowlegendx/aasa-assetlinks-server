defmodule AasaAssetlinksServer.Assetlinks do
  @moduledoc false

  use Plug.Router

  alias AasaAssetlinksServer.InmemStore

  plug :match
  plug :dispatch

  put "/" do
    case InmemStore.set_assetlinks_app(conn.body_params["app_id"], conn.body_params) do
      :ok ->
        send_resp(conn, 204, "")

      {:error, {:wrong_format, "" <> message, _context}} ->
        conn
        |> put_resp_content_type("application/json")
        |> send_resp(400, :json.encode(%{code: nil, message: message}))

      {:error, :store_not_ready} ->
        conn
        |> put_resp_content_type("application/json")
        |> send_resp(422, :json.encode(%{code: nil, message: "memory store not ready"}))
    end
  end

  delete "/" do
    :ok = InmemStore.remove_assetlinks_app(conn.body_params["app_id"])

    send_resp(conn, 204, "")
  end
end
