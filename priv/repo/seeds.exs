alias Gossip.Accounts
alias Gossip.Applications
alias Gossip.Channels
alias Gossip.Games
alias Gossip.Repo

{:ok, channel} = Channels.create(%{name: "gossip"})
channel
|> Ecto.Changeset.change(%{hidden: false})
|> Repo.update!()
{:ok, channel} = Channels.create(%{name: "testing"})
channel
|> Ecto.Changeset.change(%{hidden: false})
|> Repo.update!()

# Create a known grapevine login
{:ok, application} = Applications.create(%{name: "Grapevine", short_name: "Grapevine"})
application
|> Ecto.Changeset.change(%{
  client_id: "e16a2503-6153-48a9-9e92-3d087b9cc6d7",
  client_secret: "3de1854f-6f3a-49f4-a7f2-bc01a18c8369"
})
|> Repo.update!()

# Create a known raisin login
{:ok, application} = Applications.create(%{name: "Raisin", short_name: "Raisin"})
application
|> Ecto.Changeset.change(%{
  client_id: "c922b500-bbf8-4944-8c40-3c5559376c96",
  client_secret: "b178f27b-df94-4324-abf8-d82be5e91419"
})
|> Repo.update!()

# Create a know user and game login
{:ok, user} = Accounts.register(%{
  email: "admin@example.com",
  password: "password",
  password_confirmation: "password",
})

{:ok, game} = Games.register(user, %{name: "Development Game", short_name: "DevGame"})
game
|> Ecto.Changeset.change(%{
  client_id: "62a8988e-f505-4e9a-ad21-e04e89f1b32b",
  client_secret: "3ab47e7e-010f-488a-b7d6-a474440efda5"
})
|> Repo.update!()
