defmodule Grapevine.TestHelpers do
  alias Grapevine.Accounts
  alias Grapevine.Achievements
  alias Grapevine.Applications
  alias Grapevine.Authorizations
  alias Grapevine.Channels
  alias Grapevine.Games
  alias Grapevine.Gauges

  def create_channel(attributes \\ %{}) do
    attributes =
      Map.merge(
        %{
          name: "grapevine",
          desription: "A channel"
        },
        attributes
      )

    {:ok, channel} = Channels.create(attributes)

    channel
  end

  def create_user(attributes \\ %{}) do
    attributes =
      Map.merge(
        %{
          username: "adminuser",
          email: "admin@example.com",
          password: "password",
          password_confirmation: "password"
        },
        attributes
      )

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
    Map.merge(
      %{
        name: "A MUD",
        short_name: "AM"
      },
      attributes
    )
  end

  def create_application(attributes \\ %{}) do
    attributes =
      Map.merge(
        %{
          name: "Grapevine",
          short_name: "Grapevine"
        },
        attributes
      )

    {:ok, application} = Applications.create(attributes)

    application
  end

  def presence_state(game, state) do
    Map.merge(
      %{
        game: game,
        supports: [],
        channels: [],
        players: []
      },
      state
    )
  end

  def create_achievement(game, attributes \\ %{}) do
    attributes =
      Map.merge(
        %{
          "title" => "Adventuring",
          "description" => "You made it to level 2!",
          "points" => 10
        },
        attributes
      )

    {:ok, achievement} = Achievements.create(game, attributes)
    achievement
  end

  def create_authorization(user, game) do
    {:ok, authorization} = Authorizations.start_auth(user, game, %{
      "state" => "my+state",
      "redirect_uri" => "https://example.com/oauth/callback",
      "scope" => "profile"
    })
    {:ok, authorization} = Authorizations.authorize(authorization)

    authorization
  end

  def create_gauge(game, attributes) do
    attributes = Map.merge(%{
      name: "HP",
      package: "Char 1",
      message: "Char.Vitals",
      value: "hp",
      max: "maxhp",
      color: "red"
    }, attributes)

    {:ok, gauge} = Gauges.create(game, attributes)
    gauge
  end
end
