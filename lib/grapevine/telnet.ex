defmodule Grapevine.Telnet do
  @moduledoc """
  Telnet context, for finding MSSP data on a MUD
  """

  @telnet Application.get_env(:grapevine, :modules)[:telnet]

  @callback check_connection(Connection.t()) :: :ok

  @doc """
  Trigger a check for connection MSSP stats
  """
  def check_connection(connection) do
    @telnet.check_connection(connection)
  end
end
