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

  defp get_app(app, app_id) do
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

  def handle_call({:set_aasa_webcredential, app_id}, _from, state) do
    app = get_app(:aasa, app_id)

    data =
      if app do
        app
        |> elem(1)
        |> Map.put("webcredential", %{})
      else
        %{new_aasa() | "webcredential" => %{}}
      end

    :ets.insert(
      :aasa_assetlinks,
      {construct_aasa_app_ets_key(app_id), data}
    )

    {:reply, :ok, state}
  end

  def handle_call({:remove_aasa_webcredential, app_id}, _from, state) do
    app = get_app(:aasa, app_id)

    if app do
      :ets.insert(
        :aasa_assetlinks,
        {construct_aasa_app_ets_key(app_id), app |> elem(1) |> Map.put("webcredential", nil)}
      )
    end

    {:reply, :ok, state}
  end

  def handle_call({:set_aasa_applink, {app_id, app_link}}, _from, state) do
    app = get_app(:aasa, app_id)

    data =
      if app do
        app
        |> elem(1)
        |> Map.put("applink", %{"components" => app_link["components"]})
      else
        %{new_aasa() | "applink" => %{"components" => app_link["components"]}}
      end

    :ets.insert(
      :aasa_assetlinks,
      {construct_aasa_app_ets_key(app_id), data}
    )

    {:reply, :ok, state}
  end

  def handle_call({:remove_aasa_applink, app_id}, _from, state) do
    app = get_app(:aasa, app_id)

    if app do
      :ets.insert(
        :aasa_assetlinks,
        {construct_aasa_app_ets_key(app_id), app |> elem(1) |> Map.put("applink", nil)}
      )
    end

    {:reply, :ok, state}
  end

  def handle_call({:set_assetlinks_relations, {app_id, relations}}, _from, state) do
    app = get_app(:assetlinks, app_id)

    data =
      if app do
        %{elem(app, 1) | "relation" => relations}
      else
        %{new_assetlinks() | "relation" => relations, "namespace" => derive_assetlinks_namespace(app_id)}
      end

    :ets.insert(
      :aasa_assetlinks,
      {construct_assetlinks_app_ets_key(app_id), data}
    )

    {:reply, :ok, state}
  end

  def handle_call({:set_assetlinks_fingerprints, {app_id, sha256_fingerprints}}, _from, state) do
    namespace = derive_assetlinks_namespace(app_id)

    if namespace == "android_app" do
      app = get_app(:assetlinks, app_id)

      data =
        if app do
          %{elem(app, 1) | "sha256_cert_fingerprints" => sha256_fingerprints}
        else
          %{new_assetlinks() | "sha256_cert_fingerprints" => sha256_fingerprints, "namespace" => namespace}
        end

      :ets.insert(
        :aasa_assetlinks,
        {construct_assetlinks_app_ets_key(app_id), data}
      )

      {:reply, :ok, state}
    else
      {:reply, {:error, {:invalid_request, "app_id is not type of android_app", {app_id, sha256_fingerprints}}}, state}
    end
  end

  def set_aasa_webcredential(app_id) do
    GenServer.call(:global.whereis_name(__MODULE__), {:set_aasa_webcredential, app_id})
  end

  def remove_aasa_webcredential(app_id) do
    GenServer.call(:global.whereis_name(__MODULE__), {:remove_aasa_webcredential, app_id})
  end

  def set_aasa_applink(app_id, applink) do
    GenServer.call(:global.whereis_name(__MODULE__), {:set_aasa_applink, {app_id, applink}})
  end

  def remove_aasa_applink(app_id) do
    GenServer.call(:global.whereis_name(__MODULE__), {:remove_aasa_applink, app_id})
  end

  def set_assetlinks_relations(app_id, relations) do
    GenServer.call(:global.whereis_name(__MODULE__), {:set_assetlinks_relations, {app_id, relations}})
  end

  def set_assetlinks_fingerprints(app_id, sha256_fingerprints) do
    GenServer.call(:global.whereis_name(__MODULE__), {:set_assetlinks_fingerprints, {app_id, sha256_fingerprints}})
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
