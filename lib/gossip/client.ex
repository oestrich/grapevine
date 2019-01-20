defmodule Gossip.Client do
  @moduledoc """
  A local fake "client" to the socket
  """

  @doc """
  Send a tell to a player
  """
  @callback send_tell(to_game :: String.t(), to_player :: String.t(), message :: String.t()) :: :ok

  @client Application.get_env(:gossip, :modules)[:client]

  @doc """
  Local client presence data

  Gets injected to the online games
  """
  def presence() do
    %Gossip.Presence.State{
      game: %Gossip.Client.Application{},
      players: ["system"],
      channels: [],
      supports: ["channels", "players", "tells"],
      type: :gossip,
      timestamp: Timex.now()
    }
  end

  @doc """
  Send a tell to a game
  """
  def send_tell(to_game, to_player, message) do
    @client.send_tell(to_game, to_player, message)
  end
end
