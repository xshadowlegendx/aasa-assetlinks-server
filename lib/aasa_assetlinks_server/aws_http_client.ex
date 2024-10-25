defmodule AasaAssetlinksServer.AwsHttpClient do
  @moduledoc false

  @behaviour ExAws.Request.HttpClient

  def request(method, url, req_body, headers, http_opts) do
    req = Finch.build(method, url, headers, req_body, http_opts)

    case Finch.request(req, FinchHttpClient) do
      {:ok, %Finch.Response{} = resp} ->
        resp_body =
          if method == :get do
            resp.body
          else
            parse_xml_response_body(resp.body)
          end

        {
          :ok,
          %{
            body: resp_body,
            headers: resp.headers,
            status_code: resp.status
          }
        }

      {:error, reason} ->
        {:error, %{reason: reason}}
    end
  end

  def parse_xml_response_body(""),
    do: nil

  def parse_xml_response_body("" <> resp_body) do
    case :fxml_stream.parse_element(resp_body) do
      {:xmlel, _, _, resp} ->
        Enum.reduce(
          resp,
          %{},
          &Map.put(
            &2,
            elem(&1, 1),
            elem(&1, 3) |> Keyword.get(:xmlcdata)
          )
        )

      {:error, reason} ->
        {:error, reason}
    end
  end
end
