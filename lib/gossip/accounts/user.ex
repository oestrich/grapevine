defmodule Gossip.Accounts.User do
  use Gossip.Schema

  alias Gossip.Games.Game

  schema "users" do
    field(:email, :string)
    field(:password, :string, virtual: true)
    field(:password_confirmation, :string, virtual: true)
    field(:password_hash, :string)

    field(:token, Ecto.UUID)

    has_many(:games, Game)

    timestamps()
  end

  def changeset(struct, params) do
    struct
    |> cast(params, [:email, :password, :password_confirmation])
    |> validate_required([:email])
    |> validate_format(:email, ~r/.+@.+\..+/)
    |> ensure(:token, UUID.uuid4())
    |> hash_password()
    |> validate_required([:password_hash])
    |> validate_confirmation(:password)
    |> unique_constraint(:email)
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
