defmodule Web.SocketHelper do
  @moduledoc """
  Helpers for the socket url
  """

  @tls Application.get_env(:gossip, :socket)[:tls]
  @host Application.get_env(:gossip, Web.Endpoint)[:url][:host]
  @port Application.get_env(:gossip, Web.Endpoint)[:http][:port]

  @doc """
  Generate the socket URL based on the phoenix configuration
  """
  def socket_url() do
    uri = %URI{
      scheme: scheme(),
      host: @host,
      path: "/socket",
      port: port()
    }

    URI.to_string(uri)
  end

  if @tls do
    defp scheme(), do: "wss"
  else
    defp scheme(), do: "ws"
  end

  if @port == 4001 do
    defp port(), do: 4001
  else
    defp port(), do: nil
  end
end
