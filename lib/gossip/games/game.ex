defmodule Gossip.Games.Game do
  use Gossip.Schema

  schema "games" do
    field(:name, :string)
    field(:email, :string)
    field(:password, :string, virtual: true)
    field(:password_confirmation, :string, virtual: true)
    field(:password_hash, :string)

    field(:token, Ecto.UUID)
    field(:client_id, Ecto.UUID)
    field(:client_secret, Ecto.UUID)

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

  defp hash_password(changeset) do
    case changeset do
      %{valid?: true, changes: %{password: password}} ->
        put_change(changeset, :password_hash, Comeonin.Bcrypt.hashpwsalt(password))

      _ ->
        changeset
    end
  end
end
