defmodule Gossip.TestHelpers do
  alias Gossip.Channels
  alias Gossip.Games

  def create_channel(attributes \\ %{}) do
    attributes = Map.merge(%{
      name: "gossip",
      desription: "A channel",
    }, attributes)

    {:ok, channel} = Channels.create(attributes)

    channel
  end

  def create_game(attributes \\ %{}) do
    attributes = Map.merge(%{
      name: "A MUD",
      email: "admin@example.com",
      password: "password",
      password_confirmation: "password",
    }, attributes)

    {:ok, game} = Games.register(attributes)

    game
  end
end
