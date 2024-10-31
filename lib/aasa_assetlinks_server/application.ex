defmodule AasaAssetlinksServer.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      {Finch, name: FinchHttpClient},
      {
        Cluster.Supervisor,
        [
          Application.get_env(:libcluster, :topologies),
          [name: AasaAssetlinksServer.ClusterSupervisor]
        ]
      },
      AasaAssetlinksServer.InmemStore,
      AasaAssetlinksServer.NodeMessenger,
      {Bandit, plug: AasaAssetlinksServer.Router, scheme: :http, port: 4000}
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: AasaAssetlinksServer.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
