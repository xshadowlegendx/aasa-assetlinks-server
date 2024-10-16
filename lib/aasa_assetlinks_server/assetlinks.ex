defmodule AasaAssetlinksServer.Assetlinks do
  @moduledoc false

  use Plug.Router

  plug :match
  plug :dispatch

  post "app/relations" do
    send_resp(conn, 204, "")
  end

  delete "app/relations/:idx" do
    send_resp(conn, 204, "")
  end

  post "app/fingerprints" do
    send_resp(conn, 204, "")
  end

  delete "app/fingerprints/:idx" do
    send_resp(conn, 204, "")
  end
end

