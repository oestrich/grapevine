defmodule Gossip.Games.Game do
  use Gossip.Schema

  alias Gossip.Channels.SubscribedChannel

  schema "games" do
    field(:name, :string)
    field(:email, :string)
    field(:password, :string, virtual: true)
    field(:password_confirmation, :string, virtual: true)
    field(:password_hash, :string)
    field(:user_agent, :string)

    field(:token, Ecto.UUID)
    field(:client_id, Ecto.UUID)
    field(:client_secret, Ecto.UUID)

    has_many(:subscribed_channels, SubscribedChannel)
    has_many(:channels, through: [:subscribed_channels, :channel])

    timestamps()
  end

  def changeset(struct, params) do
    struct
    |> cast(params, [:name, :email, :password, :password_confirmation])
    |> validate_required([:name, :email])
    |> validate_format(:email, ~r/.+@.+\..+/)
    |> ensure(:token, UUID.uuid4())
    |> ensure(:client_id, UUID.uuid4())
    |> ensure(:client_secret, UUID.uuid4())
    |> hash_password()
    |> validate_required([:password_hash])
    |> validate_confirmation(:password)
    |> unique_constraint(:name)
    |> unique_constraint(:email)
  end

  def user_agent_changeset(struct, params) do
    cast(struct, params, [:user_agent])
  end

  defp hash_password(changeset) do
    case changeset do
      %{valid?: true, changes: %{password: password}} ->
        put_change(changeset, :password_hash, Comeonin.Bcrypt.hashpwsalt(password))

      _ ->
        changeset
    end
  end
end
