defmodule AasaAssetlinksServer.NodeMessenger do
  @moduledoc false

  use GenServer

  require Logger

  def start_link(_opts) do
    GenServer.start_link(__MODULE__, nil, name: __MODULE__)
  end

  def init(_opts) do
    Logger.info("node messenger started - #{Kernel.inspect(self())}")

    {:ok, nil}
  end

  def handle_info({:ets_sync_data, store_data}, state) do
    {:ok, _ets_table} = AasaAssetlinksServer.InmemStore.sync_ets_data(store_data)

    {:noreply, state}
  end
end
