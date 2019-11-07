defmodule Metrics do
  @moduledoc """
  Client to the main metrics server
  """

  @doc """
  Let the server know a socket came online
  """
  def socket_online() do
    GenServer.cast({:global, pid()}, {:socket, :online, self()})
  end

  defp pid() do
    {:grapevine, :metrics}
  end
end
