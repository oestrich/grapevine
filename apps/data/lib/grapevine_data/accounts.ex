defmodule GrapevineData.Accounts do
  @moduledoc """
  Context for accounts
  """

  import Ecto.Query
  require Logger

  alias GrapevineData.Accounts.User
  alias GrapevineData.Games.Game
  alias GrapevineData.Repo
  alias Stein.Pagination

  @type id :: integer()
  @type user_params :: map()
  @type username :: String.t()
  @type registration_key :: UUID.t()
  @type token :: String.t()

  @doc """
  Start a new user
  """
  @spec new() :: Ecto.Changeset.t()
  def new(), do: %User{} |> User.create_changeset(%{})

  @doc """
  Start editing a user
  """
  @spec edit(User.t()) :: Ecto.Changeset.t()
  def edit(user), do: user |> User.update_without_username_changeset(%{})

  @doc """
  Check for admin status on a user
  """
  def is_admin?(%{role: "admin"}), do: true

  def is_admin?(_), do: false

  @doc """
  Check for admin status on a editor
  """
  def is_editor?(%{role: "editor"}), do: true

  def is_editor?(_), do: false

  @doc """
  Register a new user
  """
  def register(params, fun) do
    changeset = %User{} |> User.create_changeset(params)

    case Repo.insert(changeset) do
      {:ok, user} ->
        :telemetry.execute([:grapevine, :accounts, :create], %{count: 1})
        fun.(user)
        {:ok, user}

      {:error, changeset} ->
        {:error, changeset}
    end
  end

  @doc """
  Update a user

  May send a new email verification if the email changes
  """
  def update(user, params, fun) do
    case is_nil(user.username) do
      true ->
        user
        |> User.update_with_username_changeset(params)
        |> Repo.update()
        |> fun.(user)

      false ->
        user
        |> User.update_without_username_changeset(params)
        |> Repo.update()
        |> fun.(user)
    end
  end

  @doc """
  Change a user's password

  Validates the password before changing
  """
  def change_password(user, current_password, params) do
    case validate_login(user.email, current_password) do
      {:error, :invalid} ->
        {:error, :invalid}

      {:ok, user} ->
        user
        |> User.password_changeset(params)
        |> Repo.update()
    end
  end

  @doc """
  Get all users

  For admins
  """
  def all(opts \\ []) do
    opts = Enum.into(opts, %{})
    query = order_by(User, [u], asc: u.username)
    Pagination.paginate(Repo, query, opts)
  end

  @doc """
  Get a user by id
  """
  @spec get(id()) :: {:ok, User.t()} | {:error, :not_found}
  def get(id) do
    case Repo.get_by(User, id: id) do
      nil ->
        {:error, :not_found}

      user ->
        {:ok, user}
    end
  end

  @doc """
  Find a user by the token
  """
  @spec from_token(token()) :: {:ok, User.t()} | {:error, :not_found}
  def from_token(token) do
    case Repo.get_by(User, token: token) do
      nil ->
        {:error, :not_found}

      user ->
        {:ok, preload(user)}
    end
  end

  defp preload(user) do
    Repo.preload(user, games: from(g in Game, order_by: [g.id]))
  end

  @doc """
  Get a user by their registration key
  """
  @spec get_by_registration_key(registration_key()) :: {:ok, User.t()} | {:error, :not_found}
  def get_by_registration_key(key) do
    case Ecto.UUID.cast(key) do
      {:ok, key} ->
        case Repo.get_by(User, registration_key: key) do
          nil ->
            {:error, :not_found}

          user ->
            {:ok, user}
        end

      _ ->
        {:error, :not_found}
    end
  end

  @doc """
  Regenerate the user's registration token
  """
  def regenerate_registration_key(user) do
    user
    |> User.regen_key_changeset()
    |> Repo.update()
  end

  @doc """
  Validate a login
  """
  @spec validate_login(String.t(), String.t()) :: {:ok, User.t()} | {:error, :invalid}
  def validate_login(email, password) do
    Stein.Accounts.validate_login(Repo, User, email, password)
  end

  @doc """
  Verify an email is valid from the token
  """
  def verify_email(token) do
    Stein.Accounts.verify_email(Repo, User, token)
  end

  @doc """
  Check if a user has verified their email
  """
  def email_verified?(user) do
    Stein.Accounts.email_verified?(user)
  end

  @doc """
  Start password reset
  """
  def start_password_reset(email, fun) do
    Stein.Accounts.start_password_reset(Repo, User, email, fun)
  end

  @doc """
  Reset a password
  """
  @spec reset_password(String.t(), map()) :: {:ok, User.t()} | :error
  def reset_password(token, params) do
    Stein.Accounts.reset_password(Repo, User, token, params)
  end

  @doc """
  Load the list of blocked usernames

  File is in `priv/users/block-list.txt`

  This file is a newline separated list of downcased names
  """
  @spec username_blocklist() :: [username()]
  def username_blocklist() do
    blocklist = Path.join(:code.priv_dir(:grapevine_data), "users/block-list.txt")
    {:ok, blocklist} = File.read(blocklist)

    blocklist
    |> String.split("\n")
    |> Enum.map(&String.trim/1)
  end
end
