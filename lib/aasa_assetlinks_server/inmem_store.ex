defmodule AasaAssetlinksServer.InmemStore do
  @moduledoc false

  use GenServer

  require Logger

  alias AasaAssetlinksServer.AasaAssetlinksApp

  @ets_tab2file_path "/tmp/ets.tab2file"
  @upload_ets_table_interval_8_minute_as_seconds 8 * 60 * 1000

  def start_link(_opts) do
    GenServer.start_link(__MODULE__, nil, name: {:global, __MODULE__})
  end

  def init(_opts) do
    {:ok, %{ready?: false, tab2file_hash: nil}, {:continue, nil}}
  end

  def handle_continue(nil, _state) do
    Logger.info("preparing inmemory store")

    if System.get_env("S3_BUCKET_NAME") in ["", nil] do
      Logger.warning("no s3 bucket configured, data will be gone if restarted or when cluster failed")
    else
      restore_ets_table_from_s3()

      Process.send_after(self(), :upload_ets_table_to_s3, @upload_ets_table_interval_8_minute_as_seconds)
    end

    if :ets.info(:aasa_assetlinks) == :undefined do
      :ets.new(:aasa_assetlinks, [:set, :public, :named_table])
    end

    Logger.info("inmemory store ready")

    tab2file_hash =
      case File.read(@ets_tab2file_path) do
        {:ok, store_data} ->
          :crypto.hash(:sha3_256, store_data)

        {:error, reason} ->
          Logger.warning("fail to read #{@ets_tab2file_path} - #{reason}")
      end

    {:noreply, %{ready?: true, tab2file_hash: tab2file_hash}}
  end

  defp s3_bucket_name(),
    do: System.get_env("S3_BUCKET_NAME")

  defp s3_ets_backup_file_path(),
    do: "#{System.get_env("S3_BUCKET_BACKUP_PATH", "backups/aasa-assetlinks")}/ets.tab2file"

  defp restore_ets_table_from_s3() do
    bucket = s3_bucket_name()

    with {:ok, :done} <- ExAws.S3.download_file(bucket, s3_ets_backup_file_path(), @ets_tab2file_path) |> ExAws.request(),
         {:ok, _} <- :ets.file2tab(:binary.bin_to_list(@ets_tab2file_path)) do
      Logger.info("ets table restored from s3")

      :ok
    else
      {:error, {:http_error, status_code, %{body: "" <> error_message}}} ->
        if String.contains?(error_message, "No such key") do
          Logger.warning("no ets.tab2file found on bucket: #{bucket}")

          nil
        else
          Logger.error("fail to get object from bucket: #{bucket}")

          raise "fail to download store file - #{status_code}, #{error_message}"
        end

      {:error, %ExAws.Error{message: "" <> error_message}} ->
        if String.contains?(error_message, "404") and String.contains?(error_message, "head") do
          Logger.warning("no ets.tab2file found on bucket: #{bucket}")

          nil
        else
          raise "fail to download store file - #{error_message}"
        end
    end
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

  defp update_applink(app, %{"applink" => applink}),
    do: %{app | "applink" => applink}

  defp update_applink(app, _),
    do: %{app | "applink" => nil}

  defp update_aasa_webcredential(app, %{"webcredential" => webcredential}),
    do: %{app | "webcredential" => webcredential}

  defp update_aasa_webcredential(app, _),
    do: %{app | "webcredential" => nil}

  defp ensure_assetlinks_app(nil), do: new_assetlinks()

  defp ensure_assetlinks_app({_, app}), do: app

  defp set_namespace(app, app_id),
    do: %{app | "namespace" => AasaAssetlinksApp.derive_assetlinks_namespace(app_id)}

  defp update_relation(app, %{"relation" => relations}),
    do: %{app | "relation" => relations}

  defp update_relation(app, _),
    do: %{app | "relation" => nil}

  defp update_cert_fingerprints(%{"namespace" => "android_app"} = app, %{"sha256_cert_fingerprints" => fingerprints}),
    do: %{app | "sha256_cert_fingerprints" => fingerprints}

  defp update_cert_fingerprints(app, _),
    do: %{app | "sha256_cert_fingerprints" => nil}

  def handle_call({_action, _data}, _from, %{ready?: false} = state),
    do: {:reply, {:error, :store_not_ready}, state}

  def handle_call({:set_aasa_app, {app_id, config}}, _from, state) do
    app = get_app(:aasa, app_id)

    config_set =
      app
      |> ensure_aasa_app()
      |> update_applink(config)
      |> update_aasa_webcredential(config)

    validation = AasaAssetlinksApp.validate_aasa_app_config(app_id, config_set)

    if validation == :ok do
      :ets.insert(
        :aasa_assetlinks,
        {construct_aasa_app_ets_key(app_id), config_set}
      )

      {:reply, :ok, state}
    else
      {:reply, validation, state}
    end
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

    validation = AasaAssetlinksApp.validate_assetlinks_app_config(app_id, config_set)

    if validation == :ok do
      :ets.insert(
        :aasa_assetlinks,
        {construct_assetlinks_app_ets_key(app_id), config_set}
      )

      {:reply, :ok, state}
    else
      {:reply, validation, state}
    end
  end

  def handle_call({:remove_assetlinks_app, app_id}, _from, state) do
    :ets.delete(:aasa_assetlinks, construct_assetlinks_app_ets_key(app_id))

    {:reply, :ok, state}
  end

  def handle_info(:upload_ets_table_to_s3, state) do
    Process.send_after(self(), :upload_ets_table_to_s3, @upload_ets_table_interval_8_minute_as_seconds)

    :ok = :ets.tab2file(:aasa_assetlinks, :binary.bin_to_list(@ets_tab2file_path))

    {:ok, store_data} = File.read(@ets_tab2file_path)

    store_data_hash = :crypto.hash(:sha3_256, store_data)

    if store_data_hash != state.tab2file_hash do
      case ExAws.S3.put_object(s3_bucket_name(), s3_ets_backup_file_path(), store_data) |> ExAws.request() do
        {:ok, %{status_code: 200}} ->
          Logger.info("data saved on s3 bucket - s3:#{s3_bucket_name()}/ets.tab2file")

        {:error, reason} ->
          Logger.error("failed to save table data onto s3 bucket - #{Kernel.inspect(reason)}")
      end
    end

    {:noreply, %{state | tab2file_hash: store_data_hash}}
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
