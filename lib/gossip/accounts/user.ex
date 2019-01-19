defmodule Gossip.Accounts.User do
  @moduledoc """
  User schema
  """

  use Ecto.Schema

  import Ecto.Changeset

  alias Gossip.Games.Game

  @type t :: %__MODULE__{}

  schema "users" do
    field(:uid, Ecto.UUID, read_after_writes: true)
    field(:username, :string)
    field(:email, :string)
    field(:password, :string, virtual: true)
    field(:password_confirmation, :string, virtual: true)
    field(:password_hash, :string)

    field(:password_reset_token, Ecto.UUID)
    field(:password_reset_expires_at, :utc_datetime_usec)

    field(:token, Ecto.UUID)

    has_many(:games, Game)

    timestamps()
  end

  def changeset(struct, params) do
    struct
    |> cast(params, [:username, :email, :password, :password_confirmation])
    |> validate_required([:username, :email])
    |> validate_format(:email, ~r/.+@.+\..+/)
    |> Gossip.Schema.ensure(:token, UUID.uuid4())
    |> hash_password()
    |> validate_required([:password_hash])
    |> validate_confirmation(:password)
    |> unique_constraint(:username)
    |> unique_constraint(:email)
  end

  def update_with_username_changeset(struct, params) do
    struct
    |> cast(params, [:username, :email])
    |> validate_required([:username, :email])
    |> validate_format(:email, ~r/.+@.+\..+/)
    |> unique_constraint(:username)
    |> unique_constraint(:email)
  end

  def update_without_username_changeset(struct, params) do
    struct
    |> cast(params, [:email])
    |> validate_required([:email])
    |> validate_format(:email, ~r/.+@.+\..+/)
    |> unique_constraint(:email)
  end

  def password_changeset(struct, params) do
    struct
    |> cast(params, [:password, :password_confirmation])
    |> validate_required([:password])
    |> validate_confirmation(:password)
    |> put_change(:password_reset_token, nil)
    |> put_change(:password_reset_expires_at, nil)
    |> hash_password
    |> validate_required([:password_hash])
  end

  def password_reset_changeset(struct) do
    struct
    |> change()
    |> put_change(:password_reset_token, UUID.uuid4())
    |> put_change(:password_reset_expires_at, Timex.now() |> Timex.shift(hours: 1))
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
