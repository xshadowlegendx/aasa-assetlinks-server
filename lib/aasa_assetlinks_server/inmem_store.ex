defmodule AasaAssetlinksServer.InmemStore do
  @moduledoc false

  use GenServer

  require Logger

  def start_link(_opts) do
    GenServer.start_link(__MODULE__, nil, name: {:global, __MODULE__})
  end

  def init(_opts) do
    {:ok, nil, {:continue, nil}}
  end

  def handle_continue(nil, _state) do
    Logger.info("preparing inmemory store")

    :ets.new(:aasa_assetlinks, [:set, :public, :named_table])

    Logger.info("inmemory store ready")

    {:noreply, %{}}
  end

  def aasa_app_ets_key_prefix, do: "aasa"

  def assetlinks_app_ets_key_prefix, do: "assetlinks"

  defp construct_aasa_app_ets_key(app_id),
    do: "#{aasa_app_ets_key_prefix()}:#{app_id}"

  defp construct_assetlinks_app_ets_key(app_id),
    do: "#{assetlinks_app_ets_key_prefix()}:#{app_id}"

  defp new_aasa() do
    %{"webcredential" => nil, "applink" => nil, "appclip" => nil}
  end

  defp new_assetlinks() do
    %{
      "relation" => [],
      "namespace" => "",
      "sha256_cert_fingerprints" => nil
    }
  end

  defp derive_assetlinks_namespace(app_id) do
    if String.match?(app_id, ~r/^https?:\/\//) do
      "web"
    else
      "android_app"
    end
  end

  def get_app(app, app_id) do
    ets_key =
      case app do
        :aasa -> construct_aasa_app_ets_key(app_id)

        :assetlinks -> construct_assetlinks_app_ets_key(app_id)
      end

    case :ets.select(:aasa_assetlinks, [{{:"$1", :"$2"}, [{:==, :"$1", ets_key}], [:"$_"]}]) do
      [app] ->
        app

      _ ->
        nil
    end
  end

  defp ensure_aasa_app(nil), do: new_aasa()

  defp ensure_aasa_app({_, app}), do: app

  defp update_applink(app, %{"applink" => %{"components" => [_|_] = components}}),
    do: %{app | "applink" => %{"components" => components}}

  defp update_applink(app, _),
    do: %{app | "applink" => nil}

  defp update_aasa_webcredential(app, %{"webcredential" => %{}}),
    do: %{app | "webcredential" => %{}}

  defp update_aasa_webcredential(app, _),
    do: %{app | "webcredential" => nil}

  defp ensure_assetlinks_app(nil), do: new_assetlinks()

  defp ensure_assetlinks_app({_, app}), do: app

  defp set_namespace(app, app_id),
    do: %{app | "namespace" => derive_assetlinks_namespace(app_id)}

  defp update_relation(app, %{"relation" => [_|_] = relations}),
    do: %{app | "relation" => relations}

  defp update_relation(app, _),
    do: %{app | "relation" => nil}

  defp update_cert_fingerprints(%{"namespace" => "android_app"} = app, %{"sha256_cert_fingerprints" => [_|_] = fingerprints}),
    do: %{app | "sha256_cert_fingerprints" => fingerprints}

  defp update_cert_fingerprints(app, _),
    do: %{app | "sha256_cert_fingerprints" => nil}

  def handle_call({:set_aasa_app, {app_id, config}}, _from, state) do
    app = get_app(:aasa, app_id)

    config_set =
      app
      |> ensure_aasa_app()
      |> update_applink(config)
      |> update_aasa_webcredential(config)

    :ets.insert(
      :aasa_assetlinks,
      {construct_aasa_app_ets_key(app_id), config_set}
    )

    {:reply, :ok, state}
  end

  def handle_call({:remove_aasa_app, app_id}, _from, state) do
    :ets.delete(:aasa_assetlinks, construct_aasa_app_ets_key(app_id))

    {:reply, :ok, state}
  end

  def handle_call({:set_assetlinks_app, {app_id, config}}, _from, state) do
    app = get_app(:assetlinks, app_id)

    config_set =
      app
      |> ensure_assetlinks_app()
      |> set_namespace(app_id)
      |> update_relation(config)
      |> update_cert_fingerprints(config)

    :ets.insert(
      :aasa_assetlinks,
      {construct_assetlinks_app_ets_key(app_id), config_set}
    )

    {:reply, :ok, state}
  end

  def handle_call({:remove_assetlinks_app, app_id}, _from, state) do
    :ets.delete(:aasa_assetlinks, construct_assetlinks_app_ets_key(app_id))

    {:reply, :ok, state}
  end

  def set_aasa_app(app_id, config) do
    GenServer.call(:global.whereis_name(__MODULE__), {:set_aasa_app, {app_id, config}})
  end

  def remove_aasa_app(app_id) do
    GenServer.call(:global.whereis_name(__MODULE__), {:remove_aasa_app, app_id})
  end

  def set_assetlinks_app(app_id, config) do
    GenServer.call(:global.whereis_name(__MODULE__), {:set_assetlinks_app, {app_id, config}})
  end

  def remove_assetlinks_app(app_id) do
    GenServer.call(:global.whereis_name(__MODULE__), {:remove_assetlinks_app, app_id})
  end

  def get_aasa_assetlinks() do
    aasa_prefix_length = String.length(aasa_app_ets_key_prefix())
    assetlinks_prefix_length = String.length(assetlinks_app_ets_key_prefix())

    %{
      "aasa" => :ets.select(:aasa_assetlinks, [
        {{:"$1", :"$2"}, [{:==, {:binary_part, :"$1", 0, aasa_prefix_length}, aasa_app_ets_key_prefix()}], [:"$_"]}
      ]),
      "assetlinks" => :ets.select(:aasa_assetlinks, [
        {{:"$1", :"$2"}, [{:==, {:binary_part, :"$1", 0, assetlinks_prefix_length}, assetlinks_app_ets_key_prefix()}], [:"$_"]}
      ])
    }
  end
end
