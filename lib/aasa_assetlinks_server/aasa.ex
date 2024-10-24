defmodule AasaAssetlinksServer.Aasa do
  @moduledoc false

  use Plug.Router

  alias AasaAssetlinksServer.InmemStore

  plug :match
  plug :dispatch

  put "/" do
    :ok = InmemStore.set_aasa_app(conn.body_params["app_id"], conn.body_params)

    send_resp(conn, 204, "")
  end

  delete "/" do
    :ok = InmemStore.remove_aasa_app(conn.body_params["app_id"])

    send_resp(conn, 204, "")
  end
end
