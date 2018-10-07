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
    attributes = Map.merge(%{
      name: "A MUD",
      short_name: "AM",
    }, attributes)

    {:ok, game} = Games.register(user, attributes)

    game
  end

  def create_application(attributes \\ %{}) do
    attributes = Map.merge(%{
      name: "Grapevine",
      short_name: "Grapevine",
    }, attributes)

    {:ok, application} = Applications.create_application(attributes)

    application
  end
end
