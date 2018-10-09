defmodule Gossip.Games do
  @moduledoc """
  Context for games
  """

  alias Gossip.Accounts.User
  alias Gossip.Games.Connection
  alias Gossip.Games.Game
  alias Gossip.Games.UserAgent
  alias Gossip.Repo

  import Ecto.Query

  @type id :: integer()
  @type game_params :: map()
  @type token :: String.t()
  @type user_agent :: String.t()
  @type game_name :: String.t()
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
  Fetch a game
  """
  @spec get(id()) :: Game.t()
  def get(game_id) do
    case Repo.get(Game, game_id) do
      nil ->
        {:error, :not_found}

      game ->
        {:ok, Repo.preload(game, [:connections])}
    end
  end

  @doc """
  Get games for a user
  """
  @spec for_user(User.t()) :: [Game.t()]
  def for_user(user) do
    Game
    |> where([g], g.user_id == ^user.id)
    |> preload([:connections])
    |> Repo.all()
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
        {:ok, Repo.preload(game, [:connections])}
    end
  end

  @doc """
  Register a new game
  """
  @spec register(User.t(), game_params()) :: {:ok, Game.t()}
  def register(user, params) do
    user
    |> Ecto.build_assoc(:games)
    |> Game.changeset(params)
    |> Repo.insert()
  end

  @doc """
  Update a game
  """
  @spec update(Game.t(), game_params()) :: {:ok, Game.t()}
  def update(game, params) do
    game
    |> Game.changeset(params)
    |> Repo.update()
  end

  @doc """
  Register a connecting games user agent
  """
  @spec register_user_agent(user_agent()) :: {:ok, UserAgent.t()}
  def register_user_agent(version) do
    case get_user_agent(version) do
      {:ok, user_agent} ->
        {:ok, user_agent}

      {:error, :not_found} ->
        create_user_agent(version)
    end
  end

  defp create_user_agent(version) do
    %UserAgent{}
    |> UserAgent.changeset(%{version: version})
    |> Repo.insert()
  end

  @doc """
  Get a user agent by its version string
  """
  @spec get_user_agent(user_agent()) :: {:ok, UserAgent.t()} | {:error, :not_found}
  def get_user_agent(version) do
    case Repo.get_by(UserAgent, version: version) do
      nil ->
        {:error, :not_found}

      user_agent ->
        {:ok, user_agent}
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
        game
        |> Game.regenerate_changeset()
        |> Repo.update()
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
        register_user_agent(user_agent)
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
    game
    |> Ecto.build_assoc(:connections)
    |> Connection.changeset(params)
    |> Repo.insert()
  end

  @doc """
  Update a game connection
  """
  def update_connection(connection, params) do
    connection
    |> Connection.update_changeset(params)
    |> Repo.update()
  end

  @doc """
  Delete a game connection
  """
  def delete_connection(connection) do
    Repo.delete(connection)
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
end
