defmodule Grapevine.Client do
  @moduledoc """
  A local fake "client" to the socket
  """

  alias Grapevine.Client.Broadcast

  @type broadcast_message :: %Broadcast{}

  @doc """
  Broadcast a message to a channel
  """
  @callback broadcast(broadcast_message()) :: :ok

  @doc """
  Send a tell to a player
  """
  @callback send_tell(to_game :: String.t(), to_player :: String.t(), message :: String.t()) ::
              :ok

  @client Application.get_env(:grapevine, :modules)[:client]

  @doc """
  Broadcast a message to a channel
  """
  def broadcast(message) do
    @client.broadcast(message)
  end

  @doc """
  Send a tell to a game
  """
  def send_tell(to_game, to_player, message) do
    @client.send_tell(to_game, to_player, message)
  end
end
