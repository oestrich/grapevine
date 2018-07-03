defmodule Gossip.Games.Game do
  use Gossip.Schema

  alias Gossip.Accounts.User
  alias Gossip.Channels.SubscribedChannel

  schema "games" do
    field(:name, :string)
    field(:user_agent, :string)

    field(:client_id, Ecto.UUID)
    field(:client_secret, Ecto.UUID)

    belongs_to(:user, User)

    has_many(:subscribed_channels, SubscribedChannel)
    has_many(:channels, through: [:subscribed_channels, :channel])

    timestamps()
  end

  def changeset(struct, params) do
    struct
    |> cast(params, [:name, :user_id])
    |> validate_required([:name, :user_id])
    |> ensure(:client_id, UUID.uuid4())
    |> ensure(:client_secret, UUID.uuid4())
    |> unique_constraint(:email)
  end

  def user_agent_changeset(struct, params) do
    cast(struct, params, [:user_agent])
  end
end
