defmodule Gossip.TestHelpers do
  alias Gossip.Accounts
  alias Gossip.Applications
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

  def create_user(attributes \\ %{}) do
    attributes = Map.merge(%{
      email: "admin@example.com",
      password: "password",
      password_confirmation: "password",
    }, attributes)

    {:ok, game} = Accounts.register(attributes)

    game
  end

  def create_game(user, attributes \\ %{}) do
    {:ok, game} = Games.register(user, game_attributes(attributes))

    game
  end

  def game_struct(attributes \\ %{}) do
    struct(Games.Game, game_attributes(attributes))
  end

  def game_attributes(attributes) do
    Map.merge(%{
      name: "A MUD",
      short_name: "AM",
    }, attributes)
  end

  def create_application(attributes \\ %{}) do
    attributes = Map.merge(%{
      name: "Grapevine",
      short_name: "Grapevine",
    }, attributes)

    {:ok, application} = Applications.create(attributes)

    application
  end

  def presence_state(game, state) do
    Map.merge(%{
      game: game,
      supports: [],
      channels: [],
      players: []
    }, state)
  end
end
