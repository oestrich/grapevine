defmodule Grapevine.Accounts.User do
  @moduledoc """
  User schema
  """

  use Ecto.Schema

  import Ecto.Changeset

  alias Grapevine.Accounts
  alias Grapevine.Authorizations.Authorization
  alias Grapevine.Characters.Character
  alias Grapevine.Games.Game

  @type t :: %__MODULE__{}

  schema "users" do
    field(:uid, Ecto.UUID, read_after_writes: true)
    field(:username, :string)
    field(:email, :string)
    field(:password, :string, virtual: true)
    field(:password_confirmation, :string, virtual: true)
    field(:password_hash, :string)
    field(:role, :string, read_after_writes: true)

    field(:password_reset_token, Ecto.UUID)
    field(:password_reset_expires_at, :utc_datetime_usec)

    field(:token, Ecto.UUID)
    field(:registration_key, Ecto.UUID, read_after_writes: true)

    has_many(:authorizations, Authorization)
    has_many(:characters, Character)
    has_many(:games, Game)

    timestamps()
  end

  def changeset(struct, params) do
    struct
    |> cast(params, [:username, :email, :password, :password_confirmation])
    |> trim(:username)
    |> trim(:email)
    |> validate_required([:username, :email])
    |> username_validation()
    |> validate_format(:email, ~r/.+@.+\..+/)
    |> Grapevine.Schema.ensure(:token, UUID.uuid4())
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
    |> username_validation()
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

  def regen_key_changeset(struct) do
    struct
    |> change()
    |> put_change(:registration_key, UUID.uuid4())
  end

  defp username_validation(changeset) do
    changeset
    |> check_username_against_block_list()
    |> validate_format(:username, ~r/^[a-zA-Z0-9-]+$/)
    |> validate_length(:username, min: 3, max: 50)
  end

  defp trim(changeset, field) do
    case get_change(changeset, field) do
      nil ->
        changeset

      value ->
        put_change(changeset, field, String.trim(value))
    end
  end

  defp hash_password(changeset) do
    case changeset do
      %{valid?: true, changes: %{password: password}} ->
        put_change(changeset, :password_hash, Comeonin.Bcrypt.hashpwsalt(password))

      _ ->
        changeset
    end
  end

  defp check_username_against_block_list(changeset) do
    case get_change(changeset, :username) do
      nil ->
        changeset

      username ->
        case Enum.member?(Accounts.username_blocklist(), String.downcase(username)) do
          true ->
            add_error(changeset, :username, "is blocked")

          false ->
            changeset
        end
    end
  end
end
