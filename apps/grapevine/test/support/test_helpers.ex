defmodule Grapevine.TestHelpers do
  alias GrapevineData.Accounts
  alias GrapevineData.Achievements
  alias GrapevineData.Authorizations
  alias GrapevineData.Channels
  alias GrapevineData.Gauges
  alias GrapevineData.Games
  alias GrapevineData.Repo

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
    {:ok, user} = Accounts.register(user_attributes(attributes), fn _user -> :ok end)
    user
  end

  def user_struct(attributes \\ %{}) do
    struct(Accounts.User, user_attributes(attributes))
  end

  def user_attributes(attributes) do
    Map.merge(
      %{
        username: "adminuser",
        email: "admin@example.com",
        password: "password",
        password_confirmation: "password"
      },
      attributes
    )
  end

  def create_game(user, attributes \\ %{}) do
    {:ok, game} = Games.register(user, game_attributes(attributes))

    {:ok, game} =
      game
      |> Ecto.Changeset.change()
      |> Ecto.Changeset.put_change(:cover_key, UUID.uuid4())
      |> Ecto.Changeset.put_change(:cover_extension, ".png")
      |> Repo.update()

    game
  end

  def game_struct(attributes \\ %{}) do
    struct(Games.Game, game_attributes(attributes))
  end

  def game_attributes(attributes) do
    Map.merge(
      %{
        name: "A MUD",
        short_name: "AM",
        description: "A MUD"
      },
      attributes
    )
  end

  def create_connection(game, attributes \\ %{}) do
    attributes =
      Map.merge(
        %{
          type: "telnet",
          host: "localhost",
          port: "5555"
        },
        attributes
      )

    {:ok, connection} = Games.create_connection(game, attributes, fn _connection -> :ok end)

    connection
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
    {:ok, authorization} =
      Authorizations.start_auth(user, game, %{
        "state" => "my+state",
        "redirect_uri" => "https://example.com/oauth/callback",
        "scope" => "profile"
      })

    {:ok, authorization} = Authorizations.authorize(authorization)

    authorization
  end

  def create_gauge(game, attributes) do
    attributes =
      Map.merge(
        %{
          name: "HP",
          package: "Char 1",
          message: "Char.Vitals",
          value: "hp",
          max: "maxhp",
          color: "red"
        },
        attributes
      )

    {:ok, gauge} = Gauges.create(game, attributes)
    gauge
  end
end
