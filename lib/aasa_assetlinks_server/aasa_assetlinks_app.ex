defmodule AasaAssetlinksServer.AasaAssetlinksApp do
  @moduledoc false

  def list_of_available_assetlinks_relations() do
    [
      "delegate_permission/common.handle_all_urls",
      "delegate_permission/common.get_login_creds"
    ]
  end

  def derive_assetlinks_namespace(app_id) do
    if String.match?(app_id, ~r/^https?:\/\//) do
      "web"
    else
      "android_app"
    end
  end

  @sha256_cert_regex ~r/^(([A-Fa-f0-9]{2})(:))(?1){30}(?2)$/
  def validate_assetlinks_app_config(
    app_id,
    %{"namespace" => "" <> namespace, "sha256_cert_fingerprints" => fingerprints, "relation" => relations} = config
  ) when is_list(fingerprints) and is_list(relations) do
    valid_relations? =
      Enum.all?(relations, fn rel -> Enum.find(list_of_available_assetlinks_relations(), & &1 == rel) end)

    valid_target_namespace? =
      namespace == derive_assetlinks_namespace(app_id)

    valid_sha256_cert_fingerprints? =
      Enum.all?(fingerprints, &String.match?(&1, @sha256_cert_regex))

    cond do
      not valid_relations? ->
        {:error, {:wrong_format, "invalid relation value", {app_id, config}}}

      not valid_target_namespace? ->
        {:error, {:wrong_format, "wrong target namespace", {app_id, config}}}

      not valid_sha256_cert_fingerprints? ->
        {:error, {:wrong_format, "wrong sha256 format", {app_id, config}}}

      true ->
        :ok
    end
  end

  def validate_assetlinks_app_config(_, config),
    do: {:error, {:wrong_format, "namespace should be string, sha256_cert_fingerprints and relation should be list", {config}}}

  @team_id_regex ~r/^[A-Z0-9]{10}$/
  @bundle_id_regex ~r/^[a-z0-9]+(\.[a-z0-9]+)*$/
  def validate_aasa_app_config(
    app_id,
    %{"webcredential" => _, "applink" => applink, "appclip" => _} = config
  ) do
    splited_app_id_part = String.split(app_id, ".")

    valid_team_id? =
      String.match?(hd(splited_app_id_part), @team_id_regex)

    valid_bundle_id? =
      splited_app_id_part
      |> Enum.drop(1)
      |> Enum.join(".")
      |> String.match?(@bundle_id_regex)

    valid_components? =
      is_map(applink) and (applink == %{} or (is_list(applink["components"]) and Enum.all?(applink["components"], &is_map/1)))

    cond do
      not valid_team_id? ->
        {:error, {:wrong_format, "invalid team id", {app_id, config}}}

      not valid_bundle_id? ->
        {:error, {:wrong_format, "invalid bundle id", {app_id, config}}}

      not valid_components? ->
        {:error, {:wrong_format, "components must be list of map", {app_id, config}}}

      true ->
        :ok
    end
  end
end
