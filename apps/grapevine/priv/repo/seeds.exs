alias GrapevineData.Accounts
alias GrapevineData.Channels
alias GrapevineData.Games
alias GrapevineData.Repo
alias GrapevineData.Statistics

{:ok, channel} = Channels.create(%{name: "gossip"})
channel
|> Ecto.Changeset.change(%{hidden: false})
|> Repo.update!()
{:ok, channel} = Channels.create(%{name: "testing"})
channel
|> Ecto.Changeset.change(%{hidden: false})
|> Repo.update!()

# Create a know user and game login
{:ok, user} =
  Accounts.register(%{
    username: "gvadmin",
    email: "admin@example.com",
    password: "password",
    password_confirmation: "password",
  }, fn _user -> :ok end)

user
|> Ecto.Changeset.change(%{role: "admin", email_verified_at: DateTime.truncate(Timex.now(), :second)})
|> Repo.update!()

{:ok, game} = Games.register(user, %{name: "Development Game", short_name: "DevGame", description: "Description for Development Game"})
game
|> Ecto.Changeset.change(%{
  enable_web_client: true,
  display_player_graph: true,
  client_id: "62a8988e-f505-4e9a-ad21-e04e89f1b32b",
  client_secret: "3ab47e7e-010f-488a-b7d6-a474440efda5"
})
|> Repo.update!()

now = Timex.now()

Enum.each(1..2190, fn i ->
  now = Timex.shift(now, minutes: -60 * i)
  seeded_players = rem(i, 80)
  {:ok, _stats} = Statistics.record_mssp_players(game, seeded_players, now)
end)

{:ok, connection} = Games.create_connection(game, %{
  type: "telnet",
  host: "localhost",
  port: 4444
}, fn _connection -> :ok end)

connection
|> Ecto.Changeset.change(%{supports_mssp: true})
|> Repo.update()

{:ok, user} =
  Accounts.register(%{
    username: "player",
    email: "player@example.com",
    password: "password",
    password_confirmation: "password",
  }, fn _user -> :ok end)

user
|> Ecto.Changeset.change(%{email_verified_at: DateTime.truncate(Timex.now(), :second)})
|> Repo.update!()
