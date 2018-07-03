defmodule Gossip.Games.Game do
  use Gossip.Schema

  alias Gossip.Accounts.User
  alias Gossip.Channels.SubscribedChannel

  schema "games" do
    field(:name, :string)
    field(:short_name, :string)
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
    |> cast(params, [:name, :short_name, :user_id])
    |> validate_required([:name, :short_name, :user_id])
    |> validate_length(:short_name, less_than_or_equal_to: 15)
    |> validate_format(:short_name, ~r/^[a-zA-Z0-9]+$/)
    |> ensure(:client_id, UUID.uuid4())
    |> ensure(:client_secret, UUID.uuid4())
    |> unique_constraint(:name)
    |> unique_constraint(:short_name)
  end

  def user_agent_changeset(struct, params) do
    cast(struct, params, [:user_agent])
  end
end
