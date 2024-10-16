defmodule AasaAssetlinksServer.Aasa do
  @moduledoc false

  use Plug.Router

  plug :match
  plug :dispatch

  post "/webcredentials" do
    send_resp(conn, 204, "")
  end

  delete "/webcredentials/:idx" do
    send_resp(conn, 204, "")
  end

  post "/applinks" do
    send_resp(conn, 204, "")
  end

  put "/applinks/:idx" do
    send_resp(conn, 204, "")
  end

  delete "/applinks/:idx" do
    send_resp(conn, 204, "")
  end
end

