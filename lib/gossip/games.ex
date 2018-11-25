defmodule Gossip.Games do
  @moduledoc """
  Context for games
  """

  alias Gossip.Accounts.User
  alias Gossip.Games.Connection
  alias Gossip.Games.Game
  alias Gossip.Games.RedirectURI
  alias Gossip.Repo
  alias Gossip.UserAgents
  alias Gossip.Versions

  import Ecto.Query

  @type id :: integer()
  @type game_params :: map()
  @type token :: String.t()
  @type game_name :: String.t()
  @type short_name :: String.t()
  @type uuid :: String.t()

  @doc """
  Start a new game
  """
  @spec new() :: Ecto.Changeset.t()
  def new(), do: %Game{} |> Game.changeset(%{})

  @doc """
  Start to a edit game
  """
  @spec edit(Game.t()) :: Ecto.Changeset.t()
  def edit(game), do: game |> Game.changeset(%{})

  @doc """
  Get all games
  """
  @spec all() :: [Game.t()]
  def all() do
    Game
    |> preload([:connections, :redirect_uris])
    |> Repo.all()
  end

  @doc """
  Get games for a user
  """
  @spec for_user(User.t()) :: [Game.t()]
  def for_user(user) do
    Game
    |> where([g], g.user_id == ^user.id)
    |> Repo.all()
  end

  @doc """
  Fetch a game
  """
  @spec get(id()) :: Game.t()
  def get(game_id) do
    case Repo.get(Game, game_id) do
      nil ->
        {:error, :not_found}

      game ->
        {:ok, Repo.preload(game, [:connections, :redirect_uris])}
    end
  end

  @doc """
  Fetch a game based on the user
  """
  @spec get(User.t(), id()) :: Game.t()
  def get(user, game_id) do
    case Repo.get_by(Game, user_id: user.id, id: game_id) do
      nil ->
        {:error, :not_found}

      game ->
        {:ok, Repo.preload(game, [:connections, :redirect_uris])}
    end
  end

  @doc """
  Fetch a game by the short name
  """
  @spec get_by_short(short_name()) :: Game.t()
  def get_by_short(short_name) do
    case Repo.get_by(Game, short_name: short_name) do
      nil ->
        {:error, :not_found}

      game ->
        {:ok, Repo.preload(game, [:connections, :redirect_uris])}
    end
  end

  @doc """
  Register a new game
  """
  @spec register(User.t(), game_params()) :: {:ok, Game.t()}
  def register(user, params) do
    changeset =
      user
      |> Ecto.build_assoc(:games)
      |> Game.changeset(params)

    case changeset |> Repo.insert() do
      {:ok, game} ->
        broadcast_game_create(game.id)
        {:ok, game}

      {:error, changeset} ->
        {:error, changeset}
    end
  end

  @doc """
  Update a game
  """
  @spec update(Game.t(), game_params()) :: {:ok, Game.t()}
  def update(game, params) do
    changeset = game |> Game.changeset(params)

    case changeset |> Repo.update() do
      {:ok, game} ->
        broadcast_game_update(game.id)
        {:ok, game}

      {:error, changeset} ->
        {:error, changeset}
    end
  end

  @doc """
  Update a game
  """
  @spec regenerate_client_tokens(User.t(), id()) :: {:ok, Game.t()}
  def regenerate_client_tokens(user, id) do
    case Repo.get_by(Game, user_id: user.id, id: id) do
      nil ->
        {:error, :not_found}

      game ->
        changeset = game |> Game.regenerate_changeset()

        case Repo.update(changeset) do
          {:ok, game} ->
            broadcast_game_update(game.id)
            {:ok, game}

          {:error, changeset} ->
            {:error, changeset}
        end
    end
  end

  @doc """
  Validate a socket
  """
  @spec validate_socket(uuid(), uuid()) :: {:ok, Game.t()} | {:error, :invalid}
  def validate_socket(client_id, client_secret, user_agent_params \\ %{}) do
    with {:ok, client_id} <- Ecto.UUID.cast(client_id),
         {:ok, client_secret} <- Ecto.UUID.cast(client_secret),
         {:ok, game} <- get_game(client_id),
         {:ok, game} <- validate_secret(game, client_secret) do
      record_metadata(game, user_agent_params)
    else
      _ ->
        {:error, :invalid}
    end
  end

  defp get_game(client_id) do
    case Repo.get_by(Game, client_id: client_id) do
      nil ->
        {:error, :invalid}

      game ->
        {:ok, game}
    end
  end

  defp validate_secret(game, client_secret) do
    case game.client_secret == client_secret do
      true ->
        {:ok, game}

      false ->
        {:error, :invalid}
    end
  end

  defp record_metadata(game, user_agent_params) do
    changeset = game |> Game.metadata_changeset(user_agent_params)

    case changeset |> Repo.update() do
      {:ok, game} ->
        broadcast_game_update(game.id)
        maybe_register_user_agent(game)
        {:ok, game}

      {:error, _} ->
        {:error, :invalid}
    end
  end

  defp maybe_register_user_agent(game) do
    case game.user_agent do
      nil ->
        :ok

      user_agent ->
        UserAgents.register_user_agent(user_agent)
    end
  end

  @doc """
  Check if a user can manage a connection
  """
  @spec user_owns_connection?(User.t(), Connection.t()) :: boolean()
  def user_owns_connection?(user, connection) do
    connection = Repo.preload(connection, :game)
    connection.game.user_id == user.id
  end

  @doc """
  Get a connection by an id
  """
  @spec get_connection(id()) :: {:ok, Connection.t()} | {:error, :not_found}
  def get_connection(id) do
    case Repo.get_by(Connection, id: id) do
      nil ->
        {:error, :not_found}

      connection ->
        {:ok, connection}
    end
  end

  @doc """
  Create a new game connection
  """
  def create_connection(game, params) do
    changeset =
      game
      |> Ecto.build_assoc(:connections)
      |> Connection.changeset(params)

    case changeset |> Repo.insert() do
      {:ok, connection} ->
        broadcast_game_update(game.id)
        {:ok, connection}

      {:error, changeset} ->
        {:error, changeset}
    end
  end

  @doc """
  Update a game connection
  """
  def update_connection(connection, params) do
    changeset = connection |> Connection.update_changeset(params)

    case changeset |> Repo.update() do
      {:ok, connection} ->
        broadcast_game_update(connection.game_id)
        {:ok, connection}

      {:error, changeset} ->
        {:error, changeset}
    end
  end

  @doc """
  Delete a game connection
  """
  def delete_connection(connection) do
    case Repo.delete(connection) do
      {:ok, connection} ->
        broadcast_game_update(connection.game_id)
        {:ok, connection}

      {:error, changeset} ->
        {:error, changeset}
    end
  end

  @doc """
  Check if a user can manage a redirect_uri
  """
  @spec user_owns_redirect_uri?(User.t(), RedirectURI.t()) :: boolean()
  def user_owns_redirect_uri?(user, redirect_uri) do
    redirect_uri = Repo.preload(redirect_uri, :game)
    redirect_uri.game.user_id == user.id
  end

  @doc """
  Get a redirect_uri by an id
  """
  @spec get_redirect_uri(id()) :: {:ok, Connection.t()} | {:error, :not_found}
  def get_redirect_uri(id) do
    case Repo.get_by(RedirectURI, id: id) do
      nil ->
        {:error, :not_found}

      redirect_uri ->
        {:ok, redirect_uri}
    end
  end

  @doc """
  Create a new redirect uri for a game
  """
  def create_redirect_uri(game, uri) do
    changeset =
      game
      |> Ecto.build_assoc(:redirect_uris)
      |> RedirectURI.changeset(uri)

    case Repo.insert(changeset) do
      {:ok, redirect_uri} ->
        broadcast_game_update(game.id)
        {:ok, redirect_uri}

      {:error, changeset} ->
        {:error, changeset}
    end
  end

  @doc """
  Delete a redirect uri from a game
  """
  def delete_redirect_uri(redirect_uri) do
    case Repo.delete(redirect_uri) do
      {:ok, redirect_uri} ->
        broadcast_game_update(redirect_uri.game_id)
        {:ok, redirect_uri}

      {:error, changeset} ->
        {:error, changeset}
    end
  end

  @doc """
  Load the list of blocked game names

  File is in `priv/games/block-list.txt`

  This file is a newline separated list of downcased names
  """
  @spec name_blocklist() :: [game_name()]
  def name_blocklist() do
    blocklist = Path.join(:code.priv_dir(:gossip), "games/block-list.txt")
    {:ok, blocklist} = File.read(blocklist)

    blocklist
    |> String.split("\n")
    |> Enum.map(&String.trim/1)
  end

  defp broadcast_game_create(game_id) do
    with {:ok, game} <- get(game_id),
         {:ok, version} <- Versions.log("create", game) do
      Web.Endpoint.broadcast("system:backbone", "games/new", version)
    else
      _ ->
        :ok
    end
  end

  defp broadcast_game_update(game_id) do
    with {:ok, game} <- get(game_id),
         {:ok, version} <- Versions.log("update", game) do
      Web.Endpoint.broadcast("system:backbone", "games/edit", version)
    else
      _ ->
        :ok
    end
  end
end
