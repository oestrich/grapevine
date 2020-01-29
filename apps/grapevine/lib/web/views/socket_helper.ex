defmodule Web.SocketHelper do
  @moduledoc """
  Helpers for the socket url
  """

  @doc """
  Generate the socket URL based on the phoenix configuration
  """
  def socket_url() do
    host = Application.get_env(:grapevine, Web.Endpoint)[:url][:host]

    uri = %URI{
      scheme: scheme(),
      host: host,
      path: "/socket",
      port: port()
    }

    URI.to_string(uri)
  end

  defp scheme() do
    case Application.get_env(:grapevine, :socket)[:tls] do
      true ->
        "wss"

      false ->
        "ws"
    end
  end

  defp port() do
    case Application.get_env(:grapevine, Web.Endpoint)[:http][:port] do
      4001 ->
        4001

      _ ->
        nil
    end
  end
end
