defmodule Metrics do
  @moduledoc """
  Client to the main metrics server
  """

  @doc """
  Let the server know a socket came online
  """
  def socket_online() do
    case :pg2.get_closest_pid(Grapevine.Metrics) do
      {:error, _reason} ->
        :error

      pid ->
        GenServer.cast(pid, {:socket, :online, self()})
    end
  end
end
