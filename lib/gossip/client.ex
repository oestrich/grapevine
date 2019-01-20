defmodule Grapevine.Client do
  @moduledoc """
  A local fake "client" to the socket
  """

  @doc """
  Send a tell to a player
  """
  @callback send_tell(to_game :: String.t(), to_player :: String.t(), message :: String.t()) :: :ok

  @client Application.get_env(:grapevine, :modules)[:client]

  @doc """
  Local client presence data

  Gets injected to the online games
  """
  def presence() do
    %Grapevine.Presence.State{
      game: %Grapevine.Client.Application{},
      players: ["system"],
      channels: [],
      supports: ["channels", "players", "tells"],
      type: :grapevine,
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
